//
//  Modifier.swift
//  DrinkingDiary
//
//  Created by yangjian on 2023/11/2.
//

import SwiftUI

struct BackgroundModifier: ViewModifier {
    func body(content: Content) -> some View {
        content.background(
            LinearGradient.linearGradient(colors: [Color("#97E8FF"), Color("#34C3FF")], startPoint: .top, endPoint: .bottom).ignoresSafeArea()
        )
    }
}

extension View {
    var background: some View {
        self.modifier(BackgroundModifier())
    }
}

struct NavigationTitleModifier: ViewModifier {
    let item: HomeRoot.State.Item
    func body(content: Content) -> some View {
        content.toolbar(content: {
            ToolbarItem(placement: .topBarLeading) {
                Image(item.titleIcon)
            }
        })
    }
}

extension View {
    func navigationBarTitle(_ item: HomeRoot.State.Item) -> some View {
        self.modifier(NavigationTitleModifier(item: item))
    }
}

extension String {
    var toHistoryDate: String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let date = dateFormatter.date(from: self)
        dateFormatter.dateFormat = "dd MMM yyyy"
        return dateFormatter.string(from: date ?? Date())
    }
}
