package com.springmvc.model;

import jakarta.persistence.*;
import java.math.BigDecimal;

@Entity(name = "Product") // <<< ชื่อ entity = "Product" ตรงกับ HQL
@Table(name = "product")
public class Product {

    @Id
    @Column(name = "productId", length = 36, nullable = false)
    private String productId;

    @Column(name = "productname", length = 100, nullable = false)
    private String productname;

    @Column(name = "description", length = 1000)
    private String description;

    @Column(name = "price", precision = 12, scale = 2, nullable = false)
    private BigDecimal price = BigDecimal.ZERO;

    @Column(name = "stock", nullable = false)
    private int stock;

    @Column(name = "categoryId", length = 36)
    private String categoryId;

    @Column(name = "farmerId", length = 36)
    private String farmerId;

    @Column(name = "availability")
    private Boolean availability;

    @Column(name = "status", length = 50)
    private String status;

    @Column(name = "img", length = 255)
    private String img;

    // ====== getters/setters ======
    public String getProductId() { return productId; }
    public void setProductId(String productId) { this.productId = productId; }

    public String getProductname() { return productname; }
    public void setProductname(String productname) { this.productname = productname; }

    public String getDescription() { return description; }
    public void setDescription(String description) { this.description = description; }

    public BigDecimal getPrice() { return price; }
    public void setPrice(BigDecimal price) { this.price = price; }

    public int getStock() { return stock; }
    public void setStock(int stock) { this.stock = stock; }

    public String getCategoryId() { return categoryId; }
    public void setCategoryId(String categoryId) { this.categoryId = categoryId; }

    public String getFarmerId() { return farmerId; }
    public void setFarmerId(String farmerId) { this.farmerId = farmerId; }

    public Boolean getAvailability() { return availability; }
    public void setAvailability(Boolean availability) { this.availability = availability; }

    public String getStatus() { return status; }
    public void setStatus(String status) { this.status = status; }

    public String getImg() { return img; }
    public void setImg(String img) { this.img = img; }
}
