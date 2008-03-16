package org.amqp.as3.codegen.model;

public class Constant {

    private String name;

    private String staticName;

    private int value;

    public String getStaticName() {
        return staticName;
    }

    public String getName() {
        return name;
    }

    public void setName(String name) {
        this.name = name;
        staticName = name.replaceAll(" ","_").toUpperCase();
    }

    public int getValue() {
        return value;
    }

    public void setValue(int value) {
        this.value = value;
    }
}
