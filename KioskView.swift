//
//  KioskView.swift
//  KioskView
//
//  Created by Minyoung Yoo on 9/13/24.
//

import SwiftUI

enum MenuType: String, CaseIterable {
    case all = "All"
    case main = "Main"
    case side = "Side"
    case dessert = "Dessert"
}

struct Menu: Identifiable, Hashable {
    var id: UUID = UUID()
    let imageName: String
    var name: String
    let price: Double
    var menuType: MenuType
    
    func showPriceToInt() -> Int {
        Int(price)
    }
}

struct OrderingListItem: Identifiable {
    var id: UUID = UUID()
    var menu: Menu
    var quantity: Int
    var totalPrice: Double {
        Double(quantity) * menu.price
    }
    
    mutating func increaseQuantity() {
        quantity += 1
    }
    
    mutating func decreaseQuantity() {
        quantity -= 1
    }
}

@Observable
class KioskDataModel {
    var dummyMenus: [Menu] = [
        Menu(imageName: "steak", name: "Steak", price: 39.00, menuType: .main),
        Menu(imageName: "frenchfries", name: "French Fries", price: 9.99, menuType: .side),
        Menu(imageName: "chococake", name: "Chocolate Cake", price: 4.99, menuType: .dessert),
        Menu(imageName: "pizza", name: "Pizza(1pc.)", price: 1.99, menuType: .main),
        Menu(imageName: "salad", name: "Salad", price: 8.99, menuType: .side),
        Menu(imageName: "icecream", name: "Ice Cream", price: 1.30, menuType: .dessert)
    ]
    
    var orderedMenus: [OrderingListItem] = []
    
    func filteredMenu(by menuType: MenuType) -> [Menu] {
        let filteredMenus = dummyMenus.filter({ $0.menuType == menuType })
        return filteredMenus
    }
    
    func getTotalPrice() -> Double {
        let totalPrice: Double = orderedMenus.reduce(0) { $0 + $1.totalPrice }
        return (totalPrice * 100).rounded() / 100
    }
}

struct KioskHorizontalScrollView: View {
    
    @Bindable var kioskDataModel: KioskDataModel
    @State private var currentFilter: MenuType = .all
    
    var filteredMenuList: [Menu] {
        var menu: [Menu] = []
        if currentFilter != .all {
            let filteredMenus = kioskDataModel.filteredMenu(by: currentFilter)
            menu = filteredMenus
            return menu
        } else {
            return kioskDataModel.dummyMenus
        }
    }
    
    var body: some View {
        ScrollView(.horizontal) {
            HStack {
                ForEach(filteredMenuList) { menu in
                    ZStack(alignment: .leading) {
                        Rectangle()
                            .fill(Color(uiColor: UIColor.systemGray5))
                            .frame(
                                width: 250,
                                height: 250
                            )
                            .cornerRadius(20)
                        
                        VStack(alignment: .leading) {
                            
                            Image(menu.imageName, label: Text("111"))
                                .resizable()
                                .frame(
                                    width: 60,
                                    height: 60
                                )
                                .clipShape(Circle())
                                .padding(.vertical)
                            
                            HStack {
                                Text("$\(NSNumber(value: menu.price))")
                                    .font(.title2)
                                    .fontWeight(.semibold)
                                
                                Spacer()
                                
                                Text("\(menu.menuType.rawValue)")
                                    .font(.caption)
                                    .padding(.trailing)
                                    .foregroundStyle(.secondary)
                            }
                            
                            Divider()
                                .padding(.trailing)
                            
                            Text("\(menu.name)")
                                .font(.title2)
                                .fontWeight(.bold)
                            
                            Spacer()
                            
                            Button {
                                addToCart(menu: menu)
                            } label: {
                                Label("Add To Cart", systemImage: "plus")
                            }
                            .buttonStyle(BorderedButtonStyle())
                            .tint(.blue)
                            .padding(.bottom)
                            
                        }
                        .padding(.leading)
                        .frame(maxHeight: .infinity, alignment: .top)
                    }
                    .frame(
                        width: 220,
                        height: 250
                    )
                    .padding(.horizontal)
                    .padding(.bottom)
                }
            }
        }
        VStack {
            Picker("Filtered Menu", selection: $currentFilter) {
                ForEach(MenuType.allCases, id: \.self) { filterType in
                    Text("\(filterType.rawValue)")
                }
            }
            .pickerStyle(
                .segmented
            )
        }
    }
    
    func addToCart(menu: Menu) {
        let isMenuAlreadyExsists = kioskDataModel.orderedMenus.contains(where: { $0.menu.name == menu.name })
        
        if !isMenuAlreadyExsists {
            kioskDataModel.orderedMenus.append(.init(menu: menu, quantity: 1))
        } else {
            print("Menu already exists")
        }
    }
}

struct KioskOrderedListView: View {
    
    @Bindable var kioskDataModel: KioskDataModel
    
    var body: some View {
        List(kioskDataModel.orderedMenus, id: \.id) { orderedMenu in
            HStack {
                Text("\(orderedMenu.menu.name)")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                Text("\(orderedMenu.menu.menuType.rawValue)")
                    .font(.title3)
                    .padding(.horizontal, 15)
                    .padding(.vertical, 5)
                    .foregroundStyle(Color(uiColor: .systemGray))
                    .background(Color(uiColor: .systemGray6))
                    .clipShape(.capsule)
                    .clipped()
                
                Text(orderedMenu.totalPrice, format: .currency(code: "USD"))
                    .font(.title3)
                    .fontWeight(.bold)
                    .padding(.horizontal, 15)
                    .padding(.vertical, 5)
                    .foregroundStyle(.white)
                    .background(Color.blue)
                    .clipShape(.capsule)
                    .clipped()
                
                Spacer()
                
                HStack {
                    Text("\(orderedMenu.quantity)")
                        .font(.title)
                        .padding(.trailing, 10)
                    
                    Stepper("Quantity") {
                        changeQuantity(menu: orderedMenu) { item in
                            if item.quantity < 100 {
                                item.increaseQuantity()
                            }
                        }
                    } onDecrement: {
                        changeQuantity(menu: orderedMenu) { item in
                            if item.quantity > 1 {
                                item.decreaseQuantity()
                            }
                        }
                    }
                    .labelsHidden()
                    .padding(.trailing)
                    
                    Button("\(Image(systemName: "trash"))", role: .destructive) {
                        deleteItem(menu: orderedMenu)
                    }
                    .buttonStyle(
                        BorderedButtonStyle()
                    )
                    .tint(.red)
                }
            }
            .frame(minHeight: 60)
        }
        .listStyle(PlainListStyle())
        .padding(.horizontal)
        .overlay {
            if kioskDataModel.orderedMenus.isEmpty {
                VStack {
                    Image(systemName: "fork.knife")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(maxWidth: 50, maxHeight: 50)
                    Text("Add Items to Order")
                }
                .foregroundColor(.secondary)
                .font(.largeTitle)
                .fontWeight(.bold)
            }
        }
    }
    
    func changeQuantity(menu: OrderingListItem, completion: (_: inout OrderingListItem) -> ()) {
        for i in 0..<kioskDataModel.orderedMenus.count {
            if kioskDataModel.orderedMenus[i].id == menu.id {
                completion(&kioskDataModel.orderedMenus[i])
            }
        }
    }
    
    func deleteItem(menu: OrderingListItem) {
        let index = kioskDataModel.orderedMenus.firstIndex(where:{ $0.id == menu.id })
        kioskDataModel.orderedMenus.remove(at: index!)
    }
}

struct KioskView: View {
    
    @State private var kioskDataModel: KioskDataModel = .init()
    
    var body: some View {
        NavigationStack {
            KioskHorizontalScrollView(kioskDataModel: kioskDataModel)
                .padding(.horizontal)
            
            KioskOrderedListView(kioskDataModel: kioskDataModel)
            
            Divider()
            
            HStack (alignment: .center) {
                Spacer()
                
                Button(action: {
                    if !kioskDataModel.orderedMenus.isEmpty {
                        print("order placed")
                        kioskDataModel.orderedMenus.removeAll()
                    } else {
                        print("the cart is empty")
                    }
                }, label: {
                    if !kioskDataModel.orderedMenus.isEmpty {
                        Label("Place Order (Total: $\(kioskDataModel.getTotalPrice().formatted()))",
                              systemImage: "cart")
                            .font(.title)
                            .fontWeight(.bold)
                            .padding(10)
                    } else {
                        Text("Your Cart is Empty")
                            .font(.title)
                            .fontWeight(.bold)
                            .padding(10)
                    }
                })
                .buttonStyle(
                    BorderedProminentButtonStyle()
                )
                .padding(.trailing)
                .disabled(kioskDataModel.orderedMenus.isEmpty ? true : false )
            }
            .padding(.vertical)
            .frame(minHeight: 130)
        }
    }
}

#Preview {
    KioskView()
}
