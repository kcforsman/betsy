require "test_helper"

describe OrdersController do
  let(:order_three) { orders(:order_three) }
  let(:order_four) { orders(:order_four) }


  describe "index" do
    it "gets the cart index" do
      get cart_path
      must_respond_with :success
    end

    it "succeeds when cart is empty" do
      order_four.order_products.each do |op|
        op.destroy
      end
      order_four.destroy
      get cart_path
      must_respond_with :success
    end
  end

  describe "show" do
    it "sucessfully gets order show page" do
      get order_path(order_three.id)

      must_respond_with :success
    end

    it "must redirect to enter_order path if order invalid" do
      id = order_three.id
      order_three.order_products.each { |order_product| order_product.destroy }
      order_three.destroy

      get order_path(id)

      must_respond_with :redirect
      must_redirect_to enter_order_path
    end
  end

  describe "update" do
    it "successfully changes both an order_product and a product attribute" do
      order = orders(:order_one)
      order_product = order_products(:order_01)
      patch order_path(order.id), params: {
        order_product: {
          order_product_id: order_product.id,
          quantity: 2
        }
      }

      updated_order_product = OrderProduct.find_by(id: order_product.id)
      updated_product = Product.find_by(name: "kombucha")

      updated_order_product.quantity.must_equal 2
      updated_product.inventory.must_equal 30

      must_respond_with :redirect
      must_redirect_to cart_path
    end

    it "doesn't save for bogus quantity (nil)" do
      order = orders(:order_one)
      order_product = order_products(:order_01)
      patch order_path(order.id), params: {
        order_product: {
          order_product_id: order_product.id,
          quantity: nil
        }
      }

      updated_order_product = OrderProduct.find_by(id: order_product.id)
      updated_product = Product.find_by(name: "kombucha")

      updated_order_product.quantity.must_equal 1
      updated_product.inventory.must_equal 31

      must_respond_with :redirect
      must_redirect_to cart_path
    end

    it "doesn't save if order_product doesn't exist" do
      order = orders(:order_one)
      order_product = order_products(:order_01)
      id = order_product.id
      order_product.destroy

      patch order_path(order.id), params: {
        order_product: {
          order_product_id: id,
          quantity: 2
        }
      }

      must_respond_with :redirect
      must_redirect_to cart_path
    end

    it "doesn't save if new quantity is greater than product inventory" do
      order = orders(:order_one)
      order_product = order_products(:order_01)

      patch order_path(order.id), params: {
        order_product: {
          order_product_id: order_product.id,
          quantity: 100
        }
      }

      updated_order_product = OrderProduct.find_by(id: order_product.id)
      updated_product = Product.find_by(name: "kombucha")

      updated_order_product.quantity.must_equal 1
      updated_product.inventory.must_equal 31

      must_respond_with :redirect
      must_redirect_to cart_path
    end

    it "doesn't save if new quantity is negative" do
      # order = orders(:order_one)
      # order_product = order_products(:order_01)
      #
      # patch order_path(order.id), params: {
      #   order_product: {
      #     order_product_id: order_product.id,
      #     quantity: 1-50
      #   }
      # }
      #
      # updated_order_product = OrderProduct.find_by(id: order_product.id)
      # updated_product = Product.find_by(name: "kombucha")
      #
      # updated_order_product.quantity.must_equal 1
      # updated_product.inventory.must_equal 31
      #
      # must_respond_with :redirect
      # must_redirect_to cart_path
    end

    it "doesn't save and destroys order_product if product has been retired" do
      # extra edge case that hasn't been implemented
    end

  end

  describe "checkout" do
    it "successfully gets checkout form page" do
      get checkout_path(orders(:order_one).id)

      must_respond_with :success
    end

    it "redirects to cart if cart is empty" do
      get checkout_path(orders(:order_five).id)

      must_respond_with :redirect
      must_redirect_to cart_path
    end
  end

  describe "paid" do
    it "successfully updates order with billing info and status to paid" do
      order = Order.find_by(id: orders(:order_one).id)

      patch order_paid_path(order.id), params: {
        order: {
          billing_email: "sdkf@jsdk",
          billing_address: "dsjfksdlfkdsfjskdfjksdjfk",
          billing_name: "sdkfjkj sldkfjkdj slkdfjkdfj",
          billing_num: "1234567890987654",
          billing_exp: "12/12",
          billing_cvv: 123,
          billing_zipcode: 12345
        }
      }

      updated_order = Order.find_by(id: orders(:order_one).id)

      updated_order.billing_email.must_equal "sdkf@jsdk"
      updated_order.status.must_equal "paid"
      must_respond_with :redirect
      must_redirect_to order_path(order.id)
    end

    it "fails to update with bogus billing data" do
      order = Order.find_by(id: orders(:order_one).id)

      patch order_paid_path(order.id), params: {
        order: {
          billing_email: nil,
          billing_address: "dsjfksdlfkdsfjskdfjksdjfk",
          billing_name: "sdkfjkj sldkfjkdj slkdfjkdfj",
          billing_num: "12345678909876",
          billing_exp: "12/12",
          billing_cvv: 123,
          billing_zipcode: 1234567
        }
      }

      must_respond_with :error
    end

    it "should redirect to root page if order DNE" do
      order = Order.find_by(id: orders(:order_one).id)
      id = order.id
      order.order_products.each { |order_product| order_product.destroy }
      order.destroy

      patch order_paid_path(id), params: {
        order: {
          billing_email: "sdkf@jsdk",
          billing_address: "dsjfksdlfkdsfjskdfjksdjfk",
          billing_name: "sdkfjkj sldkfjkdj slkdfjkdfj",
          billing_num: "1234567890987654",
          billing_exp: "12/12",
          billing_cvv: 123,
          billing_zipcode: 00000
        }
      }

      must_respond_with :redirect
      must_redirect_to root_path
    end
  end

  describe "destroy" do
    let(:order) { orders(:order_one) }

    it "successfully clears the cart of order_products, increases inventory of associated products, and redirects to cart path" do
      proc { delete order_path(order.id) }.must_change "OrderProduct.count", -2

      must_respond_with :redirect
      must_redirect_to cart_path
    end

    it "succeeds if Order does not exist" do
      id = order.id
      order.order_products.each { |order_product| order_product.destroy }
      order.destroy

      proc { delete order_path(order.id) }.wont_change "OrderProduct.count"

      must_respond_with :redirect
      must_redirect_to cart_path
    end
  end

  describe "enter_order" do
    it "successfully gets the enter order form" do
      get enter_order_path

      must_respond_with :success
    end
  end

  describe "find_order" do
    it "successfully finds and redirects to order's show view" do
      order = Order.find_by(id: orders(:order_four).id)

      get find_order_path, params: { order: {id: "#{order.id}"} }

      must_respond_with :redirect
      must_redirect_to order_path(order.id)
    end

    it "successfully finds and redirects to order's show view" do
      order = Order.find_by(id: orders(:order_four).id)
      id = order.id
      order.order_products.each { |order_product| order_product.destroy}
      order.destroy

      get find_order_path, params: { order: {id: "#{id}"} }

      must_respond_with :error
    end
  end

end
