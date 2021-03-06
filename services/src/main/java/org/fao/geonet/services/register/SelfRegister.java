//=============================================================================
//===   Copyright (C) 2001-2007 Food and Agriculture Organization of the
//===   United Nations (FAO-UN), United Nations World Food Programme (WFP)
//===   and United Nations Environment Programme (UNEP)
//===
//===   This program is free software; you can redistribute it and/or modify
//===   it under the terms of the GNU General Public License as published by
//===   the Free Software Foundation; either version 2 of the License, or (at
//===   your option) any later version.
//===
//===   This program is distributed in the hope that it will be useful, but
//===   WITHOUT ANY WARRANTY; without even the implied warranty of
//===   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
//===   General Public License for more details.
//===
//===   You should have received a copy of the GNU General Public License
//===   along with this program; if not, write to the Free Software
//===   Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA 02110-1301, USA
//===
//===   Contact: Jeroen Ticheler - FAO - Viale delle Terme di Caracalla 2,
//===   Rome - Italy. email: geonetwork@osgeo.org
//==============================================================================

package org.fao.geonet.services.register;

import java.io.File;
import java.nio.file.Path;
import java.sql.SQLException;

import jeeves.constants.Jeeves;
import jeeves.server.ServiceConfig;
import jeeves.server.context.ServiceContext;

import org.fao.geonet.GeonetContext;
import org.fao.geonet.Util;
import org.fao.geonet.constants.Geonet;
import org.fao.geonet.constants.Params;
import org.fao.geonet.domain.Address;
import org.fao.geonet.domain.Group;
import org.fao.geonet.domain.Profile;
import org.fao.geonet.domain.ReservedGroup;
import org.fao.geonet.domain.User;
import org.fao.geonet.domain.UserGroup;
import org.fao.geonet.kernel.GeonetworkDataDirectory;
import org.fao.geonet.kernel.setting.SettingInfo;
import org.fao.geonet.kernel.setting.SettingManager;
import org.fao.geonet.repository.GroupRepository;
import org.fao.geonet.repository.UserGroupRepository;
import org.fao.geonet.repository.UserRepository;
import org.fao.geonet.services.NotInReadOnlyModeService;
import org.fao.geonet.util.MailUtil;
import org.fao.geonet.util.PasswordUtil;
import org.fao.geonet.utils.Xml;
import org.jdom.Element;
import org.springframework.security.crypto.keygen.KeyGenerators;
import org.springframework.security.crypto.keygen.StringKeyGenerator;

/**
 * Register user.
 */
public class SelfRegister extends NotInReadOnlyModeService {

	private static final String PROFILE_TEMPLATE = "profileTemplate";
	private static final String PROFILE = "RegisteredUser";
	private static String FS = File.separator;
	private Path stylePath;
	private static final String PASSWORD_EMAIL_XSLT = "registration-pwd-email.xsl";
	private static final String PROFILE_EMAIL_XSLT = "registration-prof-email.xsl";

	// --------------------------------------------------------------------------
	// ---
	// --- Init
	// ---
	// --------------------------------------------------------------------------

	public void init(Path appPath, ServiceConfig params) throws Exception {
	}

	// --------------------------------------------------------------------------
	// ---
	// --- Service
	// ---
	// --------------------------------------------------------------------------

	public Element serviceSpecificExec(Element params, ServiceContext context)
			throws Exception {

        final GeonetworkDataDirectory dataDir = context.getBean(GeonetworkDataDirectory.class);
        this.stylePath = dataDir.resolveWebResource(Geonet.Path.XSLT_FOLDER).resolve("services").resolve("account");

		String surname = Util.getParam(params, Params.SURNAME);
		String name = Util.getParam(params, Params.NAME);
		String email = Util.getParam(params, Params.EMAIL);
		String profile = Util.getParam(params, Params.PROFILE);

		String address = Util.getParam(params, Params.ADDRESS, "");
		String city = Util.getParam(params, Params.CITY, "");
		String state = Util.getParam(params, Params.STATE, "");
		String zip = Util.getParam(params, Params.ZIP, "");
		String country = Util.getParam(params, Params.COUNTRY, "");

		String organ = Util.getParam(params, Params.ORG, "");
		String kind = Util.getParam(params, Params.KIND, "");

		String username = email;
		String password = getInitPassword();

		GeonetContext  gc = (GeonetContext) context.getHandlerContext(Geonet.CONTEXT_NAME);
		SettingManager sm = gc.getBean(SettingManager.class);
		
		String catalogAdminEmail = sm.getValue("system/feedback/email");
		String thisSite = sm.getSiteName();


        Element element = new Element(Jeeves.Elem.RESPONSE);
        element.setAttribute(Params.SURNAME, surname);
        element.setAttribute(Params.NAME, name);
        element.setAttribute(Params.EMAIL, email);

        final UserRepository userRepository = context.getBean(UserRepository.class);
        if (userRepository.findOneByEmail(email) != null) {
            return element.addContent(new Element("result").setText("errorEmailAddressAlreadyRegistered"));
        }

        // Add new user to database

        Group group = getGroup(context);
        String passwordHash = PasswordUtil.encode(context, password);
        User user = new User()
                .setKind(kind)
                .setName(name)
                .setOrganisation(organ)
                .setProfile(Profile.findProfileIgnoreCase(profile))
                .setSurname(surname)
                .setUsername(username);
        user.getSecurity().setPassword(passwordHash);
        user.getEmailAddresses().add(email);
        user.getAddresses().add(new Address().setAddress(address).setCountry(country).setCity(city).setState(state).setZip(zip));

        userRepository.save(user);

        // The user is created as registereduser on the GUEST group, and not mapped on the specific optional
        // profile. Then the catalogue administrator could manage the created user.
        UserGroup userGroup = new UserGroup().setUser(user).setGroup(group).setProfile(Profile.RegisteredUser);
        context.getBean(UserGroupRepository.class).save(userGroup);
		// Send email to user confirming registration

    SettingInfo si = context.getBean(SettingInfo.class);
    String siteURL = si.getSiteUrl() + context.getBaseUrl();

    if (!sendRegistrationEmail(params, password, catalogAdminEmail, thisSite, siteURL, sm)) {
        return element.addContent(new Element("result").setText("errorEmailToAddressFailed"));
    }

    // Send email to admin requesting non-standard profile if required

    if (!profile.equalsIgnoreCase(Profile.RegisteredUser.name()) && !sendProfileRequest(params, catalogAdminEmail, thisSite, siteURL, sm)) {
        return element.addContent(new Element("result").setText("errorProfileRequestFailed"));
      }

    return element.setAttribute(Params.USERNAME, username);
	}

	/**
	 * Send the mail to the registering user.
	 * 
	 * @param params
	 * @param password
	 * @param host
	 * @param port
	 * @param from
	 * @param thisSite
	 * @param siteURL
	 * @return
	 */
	private boolean sendRegistrationEmail(Element params, String password,
            String from, String thisSite,
            String siteURL, SettingManager sm) throws Exception, SQLException {
		
	    //TODO: allow internationalised emails
		
		Element root = new Element("root");
	    
	    root.addContent(new Element("site").setText(thisSite));
	    root.addContent(new Element("siteURL").setText(siteURL));
	    root.addContent((Element)params.clone());
	    root.addContent(new Element("password").setText(password));
	    
		String template = Util.getParam(params, Params.TEMPLATE, PASSWORD_EMAIL_XSLT);
	    Path emailXslt = stylePath.resolve(template);
	    Element elEmail = Xml.transform(root, emailXslt);
	    
		String email = Util.getParam(params, Params.EMAIL);
	    String subject = elEmail.getChildText("subject");
	    String message = elEmail.getChildText("content");

        return MailUtil.sendMail(email, subject, message, sm);
    }

	/**
	 * Send the profile request to the catalog administrator.
	 * 
	 * @param params
	 * @param from
	 * @param thisSite
	 * @param siteURL
	 * @return
	 */
	private boolean sendProfileRequest(Element params, String from, String thisSite, String siteURL,
			SettingManager sm) throws Exception {
		
	    //TODO: allow internationalised emails
		
	    Element root = new Element("root");
	    
	    root.addContent(new Element("site").setText(thisSite));
	    root.addContent(new Element("siteURL").setText(siteURL));
	    root.addContent((Element)params.clone());
	    
		String profileTemplate = Util.getParam(params, PROFILE_TEMPLATE, PROFILE_EMAIL_XSLT);
	    Path emailXslt = stylePath.resolve(profileTemplate);
	    Element elEmail = Xml.transform(root, emailXslt);
	    
	    String subject = elEmail.getChildText("subject");
	    String message = elEmail.getChildText("content");

        return MailUtil.sendMail(from, subject, message, sm);
    }

    // --------------------------------------------------------------------------

	/**
	 * Get group id.
   *
	 * @param context
	 * @return
	 * @throws java.sql.SQLException
	 */
	Group getGroup(ServiceContext context) throws SQLException {
        final GroupRepository bean = context.getBean(GroupRepository.class);
        return bean.findOne(ReservedGroup.guest.getId());
	}

	// --------------------------------------------------------------------------
		
	/**
	 * Get initial password - a randomly generated string.
	 */
	String getInitPassword() {
		StringKeyGenerator generator = KeyGenerators.string();
		return generator.generateKey().substring(0, 8);
	}

}
