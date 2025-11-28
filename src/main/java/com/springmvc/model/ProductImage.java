package com.springmvc.model;

import jakarta.persistence.*;
import java.sql.Timestamp;

@Entity(name = "ProductImage")
@Table(name = "product_image")
public class ProductImage {

    @Id
    @Column(name = "imageId", length = 36, nullable = false)
    private String imageId;

    @Column(name = "productId", length = 36, nullable = false)
    private String productId;

    @Column(name = "imageUrl", length = 255, nullable = false)
    private String imageUrl;

    @Column(name = "sortOrder", nullable = false)
    private Integer sortOrder = 0;

    @Column(name = "createdAt")
    private Timestamp createdAt;

    // ====== getters/setters ======
    public String getImageId() { return imageId; }
    public void setImageId(String imageId) { this.imageId = imageId; }

    public String getProductId() { return productId; }
    public void setProductId(String productId) { this.productId = productId; }

    public String getImageUrl() { return imageUrl; }
    public void setImageUrl(String imageUrl) { this.imageUrl = imageUrl; }

    public Integer getSortOrder() { return sortOrder; }
    public void setSortOrder(Integer sortOrder) { this.sortOrder = sortOrder; }

    public Timestamp getCreatedAt() { return createdAt; }
    public void setCreatedAt(Timestamp createdAt) { this.createdAt = createdAt; }
}
