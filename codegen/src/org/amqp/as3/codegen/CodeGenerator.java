package org.amqp.as3.codegen;

import org.antlr.stringtemplate.StringTemplate;
import org.antlr.stringtemplate.StringTemplateGroup;
import org.antlr.stringtemplate.language.AngleBracketTemplateLexer;
import org.apache.commons.io.IOUtils;
import org.amqp.as3.codegen.model.*;
import org.treebind.Util;

import java.io.*;
import java.util.*;

import com.ximpleware.*;

public class CodeGenerator {

    private static String baseDir = "src/org/amqp";
    private static String methodsDir = baseDir + "/methods";
    private static String headerDir = baseDir + "/headers";

    private static Map<String,String> domains;

    public static void main(String[] a) throws Exception {
        generateAS3();

    }

    private static void writeFile(String path, String name, String content) throws IOException {
        File dir = new File(path);
        if (!dir.exists()) {
            dir.mkdir();
        }
        FileWriter fstream = new FileWriter(path + "/" + name + ".as");
        BufferedWriter out = new BufferedWriter(fstream);
        out.write(content);
        out.close();
    }

    private static void generateAS3() throws Exception {

        VTDNav nav = buildNavigation("amqp0-8.xml");

        domains = bindDomains(nav);

        List<AMQPClass> classes = bindClasses(nav);

        writeConstants(nav);
        
        InputStream template = readInputFile("AMQP_Method.as.stg");
        StringTemplateGroup templates = new StringTemplateGroup(new InputStreamReader(template), AngleBracketTemplateLexer.class);

        for (AMQPClass clazz : classes) {
            for (Method method : clazz.getMethods()) {
                StringTemplate initiatingClass = templates.getInstanceOf("class");
                initiatingClass.setAttribute("method", method);
                String base = methodsDir + "/" + method.getAmqpClass().getName();
                writeFile(base, method.getName(), initiatingClass.toString());

                if (method.isSynchronous() && method.getResponse() != null) {
                    StringTemplate responseClass = templates.getInstanceOf("class");
                    responseClass.setAttribute("method", method.getResponse());
                    writeFile(base, method.getResponse().getName(), responseClass.toString());
                }
            }

            StringTemplate fieldPropertiesClass = templates.getInstanceOf("headerclass");
            fieldPropertiesClass.setAttribute("amqpclass", clazz);
            writeFile(headerDir, clazz.getCamelCaseName() + "Properties", fieldPropertiesClass.toString());

        }

        generateMethodReader("AMQP_MethodReader.as.stg", classes, methodsDir, "MethodReader");

    }

    private static void writeConstants(VTDNav nav) throws Exception {
        List<Constant> constants = bindConstants(nav);
        InputStream is = readInputFile("AMQP_Constants.as.stg");
        StringTemplateGroup constantsGroup = new StringTemplateGroup(new InputStreamReader(is), AngleBracketTemplateLexer.class);
        StringTemplate constantsClass = constantsGroup.getInstanceOf("class");
        constantsClass.setAttribute("constants", constants);
        writeFile(baseDir, "AMQP", constantsClass.toString());
    }

    private static void generateMethodReader(String template, List<AMQPClass> classes, String dir, String className) throws IOException {
        InputStream inputStream = readInputFile(template);
        StringTemplateGroup templateGroup = new StringTemplateGroup(new InputStreamReader(inputStream), AngleBracketTemplateLexer.class);
        StringTemplate readerClass = templateGroup.getInstanceOf("class");
        readerClass.setAttribute("amqpclasses", classes);
        writeFile(dir, className, readerClass.toString());
    }

    private static List<Constant> bindConstants(VTDNav nav) throws Exception {
        List<Constant> constants = new ArrayList<Constant>();

        AutoPilot ap0 = new AutoPilot();
        AutoPilot ap1 = new AutoPilot();
        AutoPilot ap2 = new AutoPilot();

        ap0.selectXPath("/amqp/constant");
        ap1.selectXPath("@name");
        ap2.selectXPath("@value");
        ap0.bind(nav);
        ap1.bind(nav);
        ap2.bind(nav);

        while (ap0.evalXPath() != -1){
            Constant constant = new Constant();
            constant.setName(ap1.evalXPathToString());
            constant.setValue((int) ap2.evalXPathToNumber());
            constants.add(constant);
        }

        ap0.resetXPath();
        ap1.resetXPath();
        ap2.resetXPath();
        AutoPilot ap3 = new AutoPilot();
        ap0.selectXPath("/amqp");
        ap1.selectXPath("@major");
        ap2.selectXPath("@minor");
        ap3.selectXPath("@port");

        ap0.bind(nav);
        ap1.bind(nav);
        ap2.bind(nav);
        ap3.bind(nav);

        // TODO This is hardcoded

        //while (ap0.evalXPath() != -1){
            Constant major = new Constant();
            major.setName("protocol major");
            major.setValue(8);
            constants.add(major);
            Constant minor = new Constant();
            minor.setName("protocol minor");
            minor.setValue(0);
            constants.add(minor);
            Constant port = new Constant();
            port.setName("port");
            port.setValue(5672);
            constants.add(port);
        //}



        return constants;
    }

    private static Map<String,String> bindDomains(VTDNav nav) throws Exception {

        Map<String,String> methods = new HashMap<String,String>();

        AutoPilot ap0 = new AutoPilot();
        AutoPilot ap1 = new AutoPilot();
        AutoPilot ap2 = new AutoPilot();

        ap0.selectXPath("/amqp/domain");
        ap1.selectXPath("@name");
        ap2.selectXPath("@type");
        ap0.bind(nav);
        ap1.bind(nav);
        ap2.bind(nav);

        while (ap0.evalXPath() != -1){
            methods.put(ap1.evalXPathToString(), ap2.evalXPathToString());
        }

        return methods;

    }


    private static List<AMQPClass> bindClasses(VTDNav nav) throws Exception {

        List<AMQPClass> classes = new ArrayList<AMQPClass>();

        AutoPilot ap0 = new AutoPilot();
        AutoPilot ap1 = new AutoPilot();
        AutoPilot ap2 = new AutoPilot();

        ap0.selectXPath("/amqp/class");
        ap1.selectXPath("@name");
        ap2.selectXPath("@index");

        ap0.bind(nav);
        ap1.bind(nav);
        ap2.bind(nav);

        while (ap0.evalXPath() != -1){
            AMQPClass clazz = new AMQPClass();

            clazz.setName(ap1.evalXPathToString());

            if (clazz.getName().equals("test")) {
                continue;
            }

            clazz.setIndex((int) ap2.evalXPathToNumber());
            List<Method> methods = new ArrayList<Method>();
            methods.addAll(bindMethods(nav, clazz, true));
            methods.addAll(bindMethods(nav, clazz, false));
            clazz.setMethods(methods);

            AutoPilot apN0 = new AutoPilot();
            AutoPilot apN1 = new AutoPilot();
            AutoPilot apN2 = new AutoPilot();
            apN0.selectXPath("field");
            apN1.selectXPath("@name");
            apN2.selectXPath("@type");
            apN0.bind(nav);
            apN1.bind(nav);
            apN2.bind(nav);

            while (apN0.evalXPath() != -1){
                Field field = new Field();
                field.setName(tokenize(apN1.evalXPathToString()));
                field.setType(apN2.evalXPathToString());
                clazz.addField(field);
            }

            classes.add(clazz);
        }

        return classes;
    }

    private static List<Method> bindMethods(VTDNav nav, AMQPClass clazz, boolean synchronous) throws Exception {

        List<Method> methods = new ArrayList<Method>();

        AutoPilot ap0 = new AutoPilot();
        AutoPilot ap1 = new AutoPilot();
        AutoPilot ap2 = new AutoPilot();
        AutoPilot ap3 = new AutoPilot();
        AutoPilot ap4 = new AutoPilot();
        AutoPilot ap5 = new AutoPilot();

        if (synchronous) {
            ap0.selectXPath("method[child::response]");
        }

        else {
            ap0.selectXPath("method[not(child::response) and not(contains(@name,'ok'))]");
        }


        ap1.selectXPath("@name");
        ap2.selectXPath("@synchronous");
        ap3.selectXPath("@index");

        if (synchronous) {
            ap4.selectXPath("response/@name");
        }

        ap5.selectXPath("@content");

        ap0.bind(nav);
        ap1.bind(nav);
        ap2.bind(nav);
        ap3.bind(nav);
        ap4.bind(nav);
        ap5.bind(nav);

        while (ap0.evalXPath() != -1){
            Method method = new Method();
            method.setAmqpClass(clazz);

            String methodName = ap1.evalXPathToString();

            if (methodName.contains("-")) {
                method.setName(Util.ToUpperCamelCase(methodName));
            }
            else {
                method.setName(Util.ToFirstUpper(methodName));
            }

            method.setSynchronous(ap2.evalXPathToBoolean() && synchronous);
            method.setHasContent(ap5.evalXPathToBoolean());
            method.setIndex((int) ap3.evalXPathToNumber());
            method.setFields(bindFlatObject(nav, Field.class, "field"));

            if (synchronous) {
                String response = ap4.evalXPathToString();
                Method r = bindMethod(nav, response, clazz);
                mangleResponseMethodName(r);
                method.setResponse(r);
            }

            methods.add(method);
        }

        return methods;
    }

    private static void mangleResponseMethodName(Method r) {
        r.setSynchronous(false);
        String name = r.getName();
        r.setName(Util.ToUpperCamelCase(name));
    }

    private static Method bindMethod(VTDNav nav, String name, AMQPClass clazz) throws Exception {
        String xpath = "/amqp/class[@name='" + clazz.getName() + "']/method[@name='" + name + "']";

        AutoPilot ap0 = new AutoPilot();
        AutoPilot ap1 = new AutoPilot();
        AutoPilot ap2 = new AutoPilot();
        AutoPilot ap3 = new AutoPilot();

        ap0.selectXPath(xpath);
        ap1.selectXPath("@name");
        ap2.selectXPath("@synchronous");
        ap3.selectXPath("@index");


        ap0.bind(nav);
        ap1.bind(nav);
        ap2.bind(nav);
        ap3.bind(nav);

        ap0.evalXPath();

        Method method = new Method();
        method.setAmqpClass(clazz);

        method.setName(ap1.evalXPathToString());
        method.setSynchronous(ap2.evalXPathToBoolean());
        method.setIndex((int) ap3.evalXPathToNumber());
        method.setFields(bindFlatObject(nav, Field.class, "field"));

        return method;

    }

    private static List bindFlatObject(VTDNav nav, Class c, String elementName) throws Exception {
        List fields = new ArrayList();
        java.lang.reflect.Field[] fields2 =  c.getDeclaredFields();
        AutoPilot[] pilots = new AutoPilot[fields2.length];
        int i = 0;
        for (java.lang.reflect.Field f : fields2) {
            AutoPilot apN = new AutoPilot();
            apN.selectXPath("@" + f.getName());
            apN.bind(nav);
            pilots[i++] = apN;

        }
        AutoPilot ap0 = new AutoPilot();
        ap0.selectXPath(elementName);
        ap0.bind(nav);
        while (ap0.evalXPath() != -1) {
            Object o = c.newInstance();
            int j = 0;
            for (java.lang.reflect.Field field : fields2) {
                field.setAccessible(true);
                setField(nav, pilots, o, j++, field);
            }
            fields.add(o);
        }

        return fields;
    }

    private static void setField(VTDNav nav, AutoPilot[] pilots, Object o, int j, java.lang.reflect.Field field) throws Exception {
        if (field.getType().isAssignableFrom(Number.class)) {
            field.set(o, (int) pilots[j].evalXPathToNumber());
        }
        else if (field.getType().isAssignableFrom(Boolean.class)) {
            field.set(o, pilots[j].evalXPathToBoolean());
        }
        else if (field.getType().isArray()) {
            field.set(o, tokenize(pilots[j].evalXPathToString()));
        }
        else {
            String type = pilots[j].evalXPathToString();
            if (type != null && type.length() > 0) {
                field.set(o, type);
            }
            else {
                AutoPilot ap0 = new AutoPilot();
                ap0.selectXPath("@domain");
                ap0.bind(nav);
                String domain = ap0.evalXPathToString();
                field.set(o, domains.get(domain));
            }
        }
    }

    private static String[] tokenize(String s) {
        return s.split("\\s");        
    }

    private static InputStream readInputFile(String templateFile) {
        InputStream is = CodeGenerator.class.getClassLoader().getResourceAsStream(templateFile);
        if (null == is) {
            throw new RuntimeException("Template file does not exist: " + templateFile);
        }
        return is;
    }

    private static VTDNav buildNavigation(String file) throws IOException, ParseException {
        byte[] input = readIntoMemory(file);

        VTDGen gen = new VTDGen();
        gen.setDoc(input);
        gen.parse(true);
        VTDNav nav = gen.getNav();
        return nav;
    }

    private static byte[] readIntoMemory(String file) throws IOException {
        InputStream spec = readInputFile(file);
        ByteArrayOutputStream buffer = new ByteArrayOutputStream();
        IOUtils.copy(spec, buffer);
        byte[] input = buffer.toByteArray();
        return input;
    }
}
