package com.springmvc.model;

import jakarta.persistence.*;
import java.time.Instant;

@Entity
@Table(name = "product_image")
public class ProductImageEntity {
    @Id
    @Column(name = "imageId", length = 64)
    private String imageId;

    @Column(name = "productId", length = 64)
    private String productId;

    @Column(name = "imageUrl", length = 255)
    private String imageUrl;

    @Column(name = "sortOrder")
    private Integer sortOrder;

    @Column(name = "createdAt")
    private Instant createdAt;

    // getters/setters
    public String getImageId() { return imageId; }
    public void setImageId(String imageId) { this.imageId = imageId; }
    public String getProductId() { return productId; }
    public void setProductId(String productId) { this.productId = productId; }
    public String getImageUrl() { return imageUrl; }
    public void setImageUrl(String imageUrl) { this.imageUrl = imageUrl; }
    public Integer getSortOrder() { return sortOrder; }
    public void setSortOrder(Integer sortOrder) { this.sortOrder = sortOrder; }
    public Instant getCreatedAt() { return createdAt; }
    public void setCreatedAt(Instant createdAt) { this.createdAt = createdAt; }
}
