package org.fao.geonet.wro4j;

import org.apache.commons.io.FileUtils;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.w3c.dom.Document;
import org.w3c.dom.Element;
import org.w3c.dom.Node;
import org.w3c.dom.NodeList;
import ro.isdc.wro.config.ReadOnlyContext;
import ro.isdc.wro.model.WroModel;
import ro.isdc.wro.model.factory.WroModelFactory;
import ro.isdc.wro.model.group.Group;
import ro.isdc.wro.model.group.Inject;
import ro.isdc.wro.model.resource.Resource;
import ro.isdc.wro.model.resource.ResourceType;
import ro.isdc.wro.util.StopWatch;

import javax.xml.parsers.DocumentBuilder;
import javax.xml.parsers.DocumentBuilderFactory;
import java.io.File;
import java.io.IOException;
import java.util.*;

/**
 * Creates model of views to javascript and css.
 * <p/>
 * User: Jesse
 * Date: 11/22/13
 * Time: 8:28 AM
 */
public class GeonetWroModelFactory implements WroModelFactory {
    private static final Logger LOG = LoggerFactory.getLogger(GeonetWroModelFactory.class);

    private static final String WRO_SOURCES_KEY = "wroSources";
    public static final String JS_SOURCE = "jsSource";
    public static final String CSS_SOURCE = "cssSource";
    public static final String WEBAPP_ATT = "webapp";
    public static final String PATH_ON_DISK_EL = "pathOnDisk";
    @Inject
    private ReadOnlyContext context;

    @Override
    public void destroy() {
        // nothing to do
    }

    @Override
    public WroModel create() {
        final StopWatch stopWatch = new StopWatch("Create Wro Model using Geonetwork");
        try {
            stopWatch.start("createModel");
            final String sourcesXmlFile = getSourcesXmlFile();
            DocumentBuilderFactory dbFactory = DocumentBuilderFactory.newInstance();
            DocumentBuilder dBuilder = dbFactory.newDocumentBuilder();
            Document doc = dBuilder.parse(sourcesXmlFile);

            final NodeList jsSources = doc.getElementsByTagName(JS_SOURCE);

            final WroModel model = new WroModel();

            final ClosureRequireDependencyManager dependencyManager = configureJavascripDependencyManager(jsSources);

            addJavascriptGroups(model, dependencyManager);

            final NodeList cssSources = doc.getElementsByTagName(CSS_SOURCE);
            addCssGroups(model, cssSources);

            return model;
        } catch (Exception e) {
            throw new RuntimeException(e);
        } finally {
            stopWatch.stop();
            LOG.debug(stopWatch.prettyPrint());
        }
    }

    private void addCssGroups(final WroModel model, final NodeList cssSources) {

        for (int i = 0; i < cssSources.getLength(); i++) {
            Node cssSource = cssSources.item(i);

            ResourceDesc desc = parseSource((Element) cssSource);

            for (File file : desc.files("css")) {
                final String name = file.getName();
                final Group group = new Group(name.substring(name.lastIndexOf('.')));
                Resource resource = new Resource();
                resource.setMinimize(true);
                resource.setType(ResourceType.CSS);
                resource.setUri(file.toURI().toString());
                model.addGroup(group);
            }
        }
        //To change body of created methods use File | Settings | File Templates.
    }

    private void addJavascriptGroups(final WroModel model, final ClosureRequireDependencyManager dependencyManager) {
        for (String moduleId : dependencyManager.getAllModuleIds()) {
            Group group = new Group(moduleId);

            final Collection<ClosureRequireDependencyManager.Node> deps =
                    dependencyManager.getTransitiveDependenciesFor(moduleId, true);

            for (ClosureRequireDependencyManager.Node dep : deps) {
                Resource resource = new Resource();
                resource.setMinimize(true);
                resource.setType(ResourceType.JS);
                resource.setUri(dep.path);
                group.addResource(resource);
            }

            model.addGroup(group);
        }
    }

    private ClosureRequireDependencyManager configureJavascripDependencyManager(final NodeList jsSources) throws IOException {
        ClosureRequireDependencyManager depManager = new ClosureRequireDependencyManager();

        for (int i = 0; i < jsSources.getLength(); i++) {
            Node jsSource = jsSources.item(i);
            ResourceDesc desc = parseSource((Element) jsSource);
            for (File file : desc.files("js")) {
                String path;
                // if servlet context is null then the build is the
                // maven build. so the path has to be the full path because
                // servletcontext is not used to locate the file.
                if (isMavenBuild()) {
                    path = file.getAbsoluteFile().toURI().toString();
                } else {
                    path = desc.relativePath + file.getPath().substring(desc.finalPath.length());
                }
                depManager.addFile(path, file);
            }
        }

        depManager.validateGraph();

        return depManager;
    }

    private ResourceDesc parseSource(final Element sourceEl) {
        ResourceDesc desc = new ResourceDesc();

        desc.relativePath = sourceEl.getAttribute(WEBAPP_ATT);
        desc.pathOnDisk = sourceEl.getAttribute(PATH_ON_DISK_EL);
        if (isMavenBuild()) {
            desc.finalPath = new File(desc.pathOnDisk, desc.relativePath).getPath();
        } else {
            desc.finalPath = context.getServletContext().getRealPath(desc.relativePath);
        }

        if (!desc.relativePath.endsWith(File.separator)) {
            desc.relativePath += File.separator;
        }

        desc.root = new File(desc.finalPath);

        return desc;
    }

    private boolean isMavenBuild() {
        return context.getServletContext() == null;
    }

    public String getSourcesXmlFile() {
        final String sourcesRawProperty = getConfigProperties().getProperty(WRO_SOURCES_KEY);
        if (context.getServletContext() != null) {
            final String[] split = sourcesRawProperty.split("WEB-INF/", 2);
            if (split.length == 2) {
                final String path = context.getServletContext().getRealPath("/WEB-INF/" + split[1]);
                if (path != null) {
                    return path;
                }
            }
        }
        return sourcesRawProperty;
    }

    protected Properties getConfigProperties() {
        return null;
    }

    public void setContext(ReadOnlyContext context) {
        this.context = context;
    }

    private static class ResourceDesc {
            String relativePath;
            String pathOnDisk;
            String finalPath;
            File root;

            public Iterable<File> files(final String extToCollect) {
                return new Iterable<File>() {

                    @Override
                    public Iterator<File> iterator() {
                        return FileUtils.iterateFiles(root, new String[]{extToCollect}, true);
                    }
                };

            }
        }
    }
