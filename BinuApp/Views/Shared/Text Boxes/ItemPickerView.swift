//
//  ItemPickerView.swift
//  BinuApp
//
//  Created by Ryan on 28/6/25.
//


import SwiftUI

struct ItemPickerView: View {
    @Binding var selectedItem: Item
    
    var body: some View {
        Form {
            ForEach(Item.allCases) { item in
                Button(action: {
                    selectedItem = item
                }) {
                    HStack {
                        Text(item.description)
                        Spacer()
                        if selectedItem == item {
                            Image(systemName: "checkmark")
                        }
                    }
                }
            }
        }
    }
}
