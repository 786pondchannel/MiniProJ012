package com.springmvc.model;

import jakarta.persistence.*;
import java.math.BigDecimal;

@Entity
@Table(name = "product")
public class Product {
    @Id
    @Column(name = "productId", length = 50)
    private String productId;

    // ตัว P ใหญ่ตามสคีมา
    @Column(name = "Productname", length = 100)
    private String productname;

    @Lob
    @Column(name = "description")
    private String description;

    @Column(name = "price", precision = 10, scale = 2)
    private BigDecimal price;

    // tinyint(1) ↔ Boolean
    @Column(name = "availability")
    private Boolean availability;

    @Column(name = "categoryId", length = 50)
    private String categoryId;

    @Column(name = "farmerId", length = 50)
    private String farmerId;

    // ตัว I ใหญ่ตามสคีมา
    @Column(name = "Img", length = 255)
    private String img;

    @Column(name = "status", length = 45)
    private String status;

    @Column(name = "stock")
    private Integer stock;

    // getters/setters
    public String getProductId() { return productId; }
    public void setProductId(String productId) { this.productId = productId; }
    public String getProductname() { return productname; }
    public void setProductname(String productname) { this.productname = productname; }
    public String getDescription() { return description; }
    public void setDescription(String description) { this.description = description; }
    public BigDecimal getPrice() { return price; }
    public void setPrice(BigDecimal price) { this.price = price; }
    public Boolean getAvailability() { return availability; }
    public void setAvailability(Boolean availability) { this.availability = availability; }
    public String getCategoryId() { return categoryId; }
    public void setCategoryId(String categoryId) { this.categoryId = categoryId; }
    public String getFarmerId() { return farmerId; }
    public void setFarmerId(String farmerId) { this.farmerId = farmerId; }
    public String getImg() { return img; }
    public void setImg(String img) { this.img = img; }
    public String getStatus() { return status; }
    public void setStatus(String status) { this.status = status; }
    public Integer getStock() { return stock; }
    public void setStock(Integer stock) { this.stock = stock; }
}
