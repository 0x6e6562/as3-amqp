package org.amqp.as3.codegen.model;

import org.treebind.Util;

import java.util.List;
import java.util.ArrayList;

public class AMQPClass {

    private int index;

    private String name;

    private String camelCaseName;

    private List<Method> methods;

    private List<Field> fields;

    public void addField(Field f) {
        if(f != null) {
            if (fields == null) {
                fields = new ArrayList<Field>();
            }
            fields.add(f);
        }
    }

    public String getCamelCaseName() {
        return camelCaseName;
    }

    public List<Field> getFields() {
        return fields;
    }

    public void setFields(List<Field> fields) {
        this.fields = fields;
    }

    public List<Method> getMethods() {
        return methods;
    }

    public void setMethods(List<Method> methods) {
        this.methods = methods;
    }

    public int getIndex() {
        return index;
    }

    public void setIndex(int index) {
        this.index = index;
    }

    public String getName() {
        return name;
    }

    public void setName(String name) {
        this.name = name;
        this.camelCaseName = Util.ToFirstUpper(name);
    }
}
