package com.springmvc.model;

import jakarta.persistence.*;
import java.time.LocalDate;

@Entity
@Table(name = "review")
public class Review {
    @Id
    @Column(name = "reviewId", length = 50)
    private String reviewId;

    @Column(name = "rating")
    private Integer rating;

    @Lob
    @Column(name = "comment")
    private String comment;

    @Column(name = "reviewDate")
    private LocalDate reviewDate;

    @Column(name = "orderId", length = 50)
    private String orderId;

    @Column(name = "memberId", length = 50)
    private String memberId;

    @Column(name = "productId", length = 50)
    private String productId;

    // getters/setters
    public String getReviewId() { return reviewId; }
    public void setReviewId(String reviewId) { this.reviewId = reviewId; }
    public Integer getRating() { return rating; }
    public void setRating(Integer rating) { this.rating = rating; }
    public String getComment() { return comment; }
    public void setComment(String comment) { this.comment = comment; }
    public LocalDate getReviewDate() { return reviewDate; }
    public void setReviewDate(LocalDate reviewDate) { this.reviewDate = reviewDate; }
    public String getOrderId() { return orderId; }
    public void setOrderId(String orderId) { this.orderId = orderId; }
    public String getMemberId() { return memberId; }
    public void setMemberId(String memberId) { this.memberId = memberId; }
    public String getProductId() { return productId; }
    public void setProductId(String productId) { this.productId = productId; }
}
