package com.springmvc.model;

import jakarta.persistence.*;

@Entity
@Table(name = "farmer")
public class Farmer {
    @Id
    @Column(name = "farmerId", length = 50)
    private String farmerId;

    @Column(name = "farmName", length = 100)
    private String farmName;

    @Column(name = "imageF", length = 255)
    private String imageF;

    @Column(name = "slipUrl", length = 255)
    private String slipUrl;

    @Column(name = "email", length = 45)
    private String email;

    // คอลัมน์ตัว A ใหญ่
    @Column(name = "Address", length = 255)
    private String address;

    @Column(name = "password", length = 45)
    private String password;

    @Column(name = "phoneNumber", length = 45)
    private String phoneNumber;

    // ในสคีมาเป็น varchar(45) (String)
    @Column(name = "rating", length = 45)
    private String rating;

    @Column(name = "farmLocation", length = 45)
    private String farmLocation;

    @Column(name = "status", length = 45)
    private String status;

    // getters/setters
    public String getFarmerId() { return farmerId; }
    public void setFarmerId(String farmerId) { this.farmerId = farmerId; }
    public String getFarmName() { return farmName; }
    public void setFarmName(String farmName) { this.farmName = farmName; }
    public String getImageF() { return imageF; }
    public void setImageF(String imageF) { this.imageF = imageF; }
    public String getSlipUrl() { return slipUrl; }
    public void setSlipUrl(String slipUrl) { this.slipUrl = slipUrl; }
    public String getEmail() { return email; }
    public void setEmail(String email) { this.email = email; }
    public String getAddress() { return address; }
    public void setAddress(String address) { this.address = address; }
    public String getPassword() { return password; }
    public void setPassword(String password) { this.password = password; }
    public String getPhoneNumber() { return phoneNumber; }
    public void setPhoneNumber(String phoneNumber) { this.phoneNumber = phoneNumber; }
    public String getRating() { return rating; }
    public void setRating(String rating) { this.rating = rating; }
    public String getFarmLocation() { return farmLocation; }
    public void setFarmLocation(String farmLocation) { this.farmLocation = farmLocation; }
    public String getStatus() { return status; }
    public void setStatus(String status) { this.status = status; }
}
