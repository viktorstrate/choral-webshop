package webshop.orchestrated.cart.messages;

import webshop.common.models.CartItem;

public final class AddItemReq@A implements CartMessage@A {
    private final String@A userID;
    private final CartItem@A item;

    public AddItemReq(String@A userID, CartItem@A item) {
        this.userID = userID;
        this.item = item;
    }

    public String@A userID() {
        return this.userID;
    }

    public CartItem@A item() {
        return this.item;
    }

    public CartCommand@A getCommand() {
        return CartCommand@A.ADD_ITEM_REQ;
    }
}