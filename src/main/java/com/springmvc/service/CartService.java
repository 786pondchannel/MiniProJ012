package com.springmvc.service;

import com.springmvc.cart.VendorCart;
import com.springmvc.model.Cart;
import com.springmvc.model.CartItem;
import com.springmvc.model.Product;
import org.springframework.stereotype.Service;

@Service
public class CartService {

    Product findById(String productId) { return null; }

    public Cart getOrCreateCart(Object sessionAttr) {
        return (sessionAttr instanceof Cart) ? (Cart) sessionAttr : new Cart();
    }

    public void addItem(Cart cart, Product p, int qty, String farmerName) {
        if (cart == null || p == null) return;

        VendorCart vcart = cart.getByFarmer().computeIfAbsent(p.getFarmerId(), id -> {
            VendorCart vc = new VendorCart();
            vc.setFarmerId(p.getFarmerId());
            vc.setFarmerName(farmerName);
            return vc;
        });

        CartItem newItem = new CartItem(
                p.getProductId(),      // ใช้ String ตรง ๆ
                p.getProductname(),
                p.getImg(),
                p.getPrice(),
                Math.max(qty, 1)
        );

        vcart.addOrMergeItem(newItem);
    }

    public void updateQty(Cart cart, String farmerId, String productId, int qty) {
        if (cart == null || farmerId == null || productId == null) return;
        var v = cart.getByFarmer().get(farmerId);
        if (v == null) return;
        v.getItems().stream()
                .filter(i -> productId.equals(i.getProductId()))
                .findFirst()
                .ifPresent(i -> i.setQty(Math.max(qty, 1)));
    }

    public void removeItem(Cart cart, String farmerId, String productId) {
        if (cart == null || farmerId == null || productId == null) return;
        var v = cart.getByFarmer().get(farmerId);
        if (v == null) return;
        v.remove(productId);
        if (v.getItems().isEmpty()) cart.clearVendor(farmerId);
    }
}
