package com.springmvc.model;

import jakarta.persistence.*;

@Entity
@Table(name = "receipt")
public class Receipt {
    @Id
    @Column(name = "receiptId", length = 50)
    private String receiptId;

    @Column(name = "ReferenceID", length = 50)
    private String referenceId;

    @Column(name = "Img", length = 255)
    private String img;

    @Column(name = "perorder_orderId", length = 50)
    private String perorderOrderId;

    // getters/setters
    public String getReceiptId() { return receiptId; }
    public void setReceiptId(String receiptId) { this.receiptId = receiptId; }
    public String getReferenceId() { return referenceId; }
    public void setReferenceId(String referenceId) { this.referenceId = referenceId; }
    public String getImg() { return img; }
    public void setImg(String img) { this.img = img; }
    public String getPerorderOrderId() { return perorderOrderId; }
    public void setPerorderOrderId(String perorderOrderId) { this.perorderOrderId = perorderOrderId; }
}
