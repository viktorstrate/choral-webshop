package webshop.events;

import webshop.events.channel.TypeSymChannel;

public class EventHandler@(Client, Cart, Billing, Shipping) {

    ClientState@Client clientState;
    CartState@Cart cartState;
    BillingState@Billing billingState;
    ShippingState@Shipping shippingState;

    TypeSymChannel@(Client, Cart)<Event> ch_clientCart;
    TypeSymChannel@(Client, Shipping)<Event> ch_clientShipping;
    TypeSymChannel@(Cart, Billing)<Event> ch_cartBilling;
    TypeSymChannel@(Billing, Shipping)<Event> ch_billingShipping;

    public EventHandler(
        TypeSymChannel@(Client, Cart)<Event> ch_clientCart,
        TypeSymChannel@(Client, Shipping)<Event> ch_clientShipping,
        TypeSymChannel@(Cart, Billing)<Event> ch_cartBilling,
        TypeSymChannel@(Billing, Shipping)<Event> ch_billingShipping,
        ClientState@Client clientState,
        CartState@Cart cartState,
        BillingState@Billing billingState,
        ShippingState@Shipping shippingState
    ) {
        this.ch_clientCart = ch_clientCart;
        this.ch_clientShipping = ch_clientShipping;
        this.ch_cartBilling = ch_cartBilling;
        this.ch_billingShipping = ch_billingShipping;

        this.clientState = clientState;
        this.cartState = cartState;
        this.billingState = billingState;
        this.shippingState = shippingState;
    }

    void on(Event@Client event) {
        switch (event.getCommand()) {
            case PLACE_ORDER -> {
                // Client -> Cart -> Billing -> Shipping -> Client
                EventPlaceOrder@Client ev_client = Utils@Client.<EventPlaceOrder>cast(event);
                ev_client.addUserID(clientState.userID);

                EventPlaceOrder@Cart ev_cart = ch_clientCart.<EventPlaceOrder>tselect(ev_client);
                ev_cart.addUserCart(cartState.getUserCart(ev_cart.userID));

                EventPlaceOrder@Billing ev_billing = ch_cartBilling.<EventPlaceOrder>tselect(ev_cart);
                Order@Billing order = billingState.makeOrder(ev_billing.userID, ev_billing.cart);
                ev_billing.addOrder(order);

                EventPlaceOrder@Shipping ev_shipping = ch_billingShipping.<EventPlaceOrder>tselect(ev_billing);
                String@Shipping shippingAddress = shippingState.shipOrder(ev_shipping.order);
                ev_shipping.addShipment(shippingAddress);

                EventPlaceOrder@Client result = ch_clientShipping.<EventPlaceOrder>tselect(ev_shipping);
                clientState.showOrderSummary(result);
            }
            case ADD_ITEM -> {
                // client -> cart
                EventAddItem@Client ev_client = Utils@Client.<EventAddItem>cast(event);
                ev_client.addUserID(clientState.userID);

                EventAddItem@Cart ev_cart = ch_clientCart.<EventAddItem>tselect(ev_client);
                this.cartState.addItem(ev_cart.userID, ev_cart.item);

                // Would be nice to get rid of these lines somehow.
                // Since the `on` method loops, these messages could be ignored and the choreographies would still align.
                EventAddItem@Billing ev_billing = ch_cartBilling.<EventAddItem>tselect(ev_cart);
                EventAddItem@Shipping ev_shipping = ch_billingShipping.<EventAddItem>tselect(ev_billing);
            }
        }
    }
}