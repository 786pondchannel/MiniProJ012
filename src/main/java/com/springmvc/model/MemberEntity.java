package com.springmvc.model;

import jakarta.persistence.*;

@Entity
@Table(name = "member")
public class MemberEntity {
    @Id
    @Column(name = "memberId", length = 50)
    private String memberId;

    // คอลัมน์ตัว F ใหญ่ / P ใหญ่ / A ใหญ่
    @Column(name = "Fullname", length = 100)
    private String fullname;

    @Column(name = "PhoneNumber", length = 255)
    private String phoneNumber;

    @Column(name = "imageUrl", length = 255)
    private String imageUrl;

    @Column(name = "Address", length = 100)
    private String address;

    @Column(name = "password", length = 45)
    private String password;

    @Column(name = "email", length = 45)
    private String email;

    @Column(name = "status", length = 45)
    private String status;

    // getters/setters
    public String getMemberId() { return memberId; }
    public void setMemberId(String memberId) { this.memberId = memberId; }
    public String getFullname() { return fullname; }
    public void setFullname(String fullname) { this.fullname = fullname; }
    public String getPhoneNumber() { return phoneNumber; }
    public void setPhoneNumber(String phoneNumber) { this.phoneNumber = phoneNumber; }
    public String getImageUrl() { return imageUrl; }
    public void setImageUrl(String imageUrl) { this.imageUrl = imageUrl; }
    public String getAddress() { return address; }
    public void setAddress(String address) { this.address = address; }
    public String getPassword() { return password; }
    public void setPassword(String password) { this.password = password; }
    public String getEmail() { return email; }
    public void setEmail(String email) { this.email = email; }
    public String getStatus() { return status; }
    public void setStatus(String status) { this.status = status; }
}
