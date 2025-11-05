package com.springmvc.model;

import java.sql.Timestamp;

/** DTO ธรรมดา ใช้สำหรับแสดงผลรูป ไม่ผูกกับ Hibernate ก็ได้ */
public class ProductImage {
    private String imageId;
    private String productId;
    private String imageUrl;
    private Integer sortOrder;
    private Timestamp createdAt;

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
