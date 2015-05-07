package org.amqp.as3.codegen.model;


public class Field {

    private String[] name;

    private String type;

    public String getType() {
        return type;
    }

    public void setType(String type) {
        this.type = type;
    }

    public String[] getName() {
        return name;
    }

    public void setName(String[] name) {
    //	String nameCheck = name.toString().replace("-", "__");
    //	if (nameCheck!=name.toString()) System.out.println("Field_setName:"+nameCheck);
        this.name = name;//nameCheck.split("");
    }
}
