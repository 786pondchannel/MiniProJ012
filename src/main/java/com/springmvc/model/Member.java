package com.springmvc.model;

import java.math.BigDecimal;

public class Member {

    // ====== fields (ตามตาราง member) ======
    private String memberId;
    private String fullname;
    private String phoneNumber;
    private String imageUrl;
    private String address;

    
    private String password;
    private String email;
    private String status;         // "MEMBER" หรือ "FARMER"

    // สำหรับบัญชีเกษตรกร
    private String farmName;       // (กรณี status=="FARMER")
    private String farmLocation;   // (กรณี status=="FARMER")

    // ====== getters / setters ======
    public String getMemberId() {
        return memberId;
    }
    public void setMemberId(String memberId) {
        this.memberId = memberId;
    }

    public String getFullname() {
        return fullname;
    }
    public void setFullname(String fullname) {
        this.fullname = fullname;
    }

    public String getPhoneNumber() {
        return phoneNumber;
    }
    public void setPhoneNumber(String phoneNumber) {
        this.phoneNumber = phoneNumber;
    }

    public String getImageUrl() {
        return imageUrl;
    }
    public void setImageUrl(String imageUrl) {
        this.imageUrl = imageUrl;
    }

    public String getAddress() {
        return address;
    }
    public void setAddress(String address) {
        this.address = address;
    }


    public String getPassword() {
        return password;
    }
    public void setPassword(String password) {
        this.password = password;
    }

    public String getEmail() {
        return email;
    }
    public void setEmail(String email) {
        this.email = email;
    }

    public String getStatus() {
        return status;
    }
    public void setStatus(String status) {
        this.status = status;
    }

    public String getFarmName() {
        return farmName;
    }
    public void setFarmName(String farmName) {
        this.farmName = farmName;
    }

    public String getFarmLocation() {
        return farmLocation;
    }
    public void setFarmLocation(String farmLocation) {
        this.farmLocation = farmLocation;
    }
}
