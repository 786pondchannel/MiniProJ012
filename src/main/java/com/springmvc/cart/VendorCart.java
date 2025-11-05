package com.springmvc.cart;

import com.springmvc.model.CartItem;

import java.math.BigDecimal;
import java.util.ArrayList;
import java.util.List;

public class VendorCart {
    private String farmerId;
    private String farmerName;
    private final List<CartItem> items = new ArrayList<>();

    public BigDecimal getSubtotal() {
        return items.stream()
                .map(CartItem::getSubtotal)
                .reduce(BigDecimal.ZERO, BigDecimal::add);
    }

    public void addOrMergeItem(CartItem newItem) {
        CartItem exist = items.stream()
                .filter(i -> i.getProductId().equals(newItem.getProductId()))
                .findFirst()
                .orElse(null);
        if (exist == null) {
            items.add(newItem);
        } else {
            exist.setQty(exist.getQty() + newItem.getQty());
        }
    }

    public void remove(String productId) {
        items.removeIf(i -> i.getProductId().equals(productId));
    }

    // getters/setters
    public String getFarmerId() { return farmerId; }
    public void setFarmerId(String farmerId) { this.farmerId = farmerId; }
    public String getFarmerName() { return farmerName; }
    public void setFarmerName(String farmerName) { this.farmerName = farmerName; }
    public List<CartItem> getItems() { return items; }
}
