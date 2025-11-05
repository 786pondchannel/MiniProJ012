package com.springmvc.model;

import jakarta.persistence.*;

@Entity
@Table(name = "preorderdetail")
public class PreorderDetail {
    @Id
    @Column(name = "preOrderId", length = 50)
    private String preOrderId;

    @Column(name = "quantity")
    private Integer quantity;

    @Column(name = "preOrderStatus", length = 50)
    private String preOrderStatus;

    @Column(name = "orderId", length = 50)
    private String orderId;

    @Column(name = "productId", length = 50)
    private String productId;

    // getters/setters
    public String getPreOrderId() { return preOrderId; }
    public void setPreOrderId(String preOrderId) { this.preOrderId = preOrderId; }
    public Integer getQuantity() { return quantity; }
    public void setQuantity(Integer quantity) { this.quantity = quantity; }
    public String getPreOrderStatus() { return preOrderStatus; }
    public void setPreOrderStatus(String preOrderStatus) { this.preOrderStatus = preOrderStatus; }
    public String getOrderId() { return orderId; }
    public void setOrderId(String orderId) { this.orderId = orderId; }
    public String getProductId() { return productId; }
    public void setProductId(String productId) { this.productId = productId; }
}
