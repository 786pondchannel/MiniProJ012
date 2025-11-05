package com.springmvc.model;

import com.springmvc.cart.VendorCart;

import java.math.BigDecimal;
import java.util.LinkedHashMap;
import java.util.Map;

public class Cart {
    // key = farmerId
    private final Map<String, VendorCart> byFarmer = new LinkedHashMap<>();

    public Map<String, VendorCart> getByFarmer() { return byFarmer; }

    public BigDecimal getGrandTotal() {
        return byFarmer.values().stream()
                .map(VendorCart::getSubtotal)
                .reduce(BigDecimal.ZERO, BigDecimal::add);
    }

    public void clearVendor(String farmerId) { byFarmer.remove(farmerId); }

    public void clearAll() { byFarmer.clear(); }
}
