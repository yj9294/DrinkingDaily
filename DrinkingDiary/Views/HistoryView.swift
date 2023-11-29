//
//  RecordListView.swift
//  DrinkingDiary
//
//  Created by yangjian on 2023/11/7.
//

import SwiftUI
import ComposableArchitecture

struct History: Reducer {
    struct State: Equatable {
        static func == (lhs: History.State, rhs: History.State) -> Bool {
            lhs.recordList == rhs.recordList
        }
        @UserDefault(key: "record:list")
        var recordList: [Record.Model]?
        
        var items: [[Record.Model]] {
            return (recordList ?? []).reduce([]) { (result, item) -> [[Record.Model]] in
                var result = result
                if result.count == 0 {
                    result.append([item])
                } else {
                    if var arr = result.last, let lasItem = arr.last, lasItem.day == item.day  {
                        arr.append(item)
                        result[result.count - 1] = arr
                    } else {
                        result.append([item])
                    }
                }
               return result
            }.reversed()
        }
    }
    enum Action: Equatable {
        case pop
    }
    var body: some Reducer<State, Action> {
        Reduce{ state, action in
            return .none
        }
    }
}

struct HistoryView: View {
    let store: StoreOf<History>
    var body: some View {
        WithViewStore(store, observe: {$0}) { viewStore in
            VStack{
                ScrollView(showsIndicators: false) {
                    LazyVGrid(columns: [GridItem(.flexible())], spacing:  20) {
                        ForEach(viewStore.items, id: \.self) { items in
                            ContentView(items: items)
                        }
                    }
                    Spacer()
                }.padding(.horizontal, 20).padding(.top, 20)
            }.navigationBarBackButtonHidden().navigationBarTitle("History Record").toolbar(content: {
                ToolbarItem(placement: .topBarLeading) {
                    Button(action: {viewStore.send(.pop)}, label: {
                        Image("back")
                    })
                }
            })
        }.background.navigationBarTitleDisplayMode(.inline)
    }
    
    struct ContentView: View {
        let items: [Record.Model]
        var body: some View {
            VStack(alignment: .leading){
                Text(items.first?.day.toHistoryDate ?? "").font(.system(size: 12)).foregroundColor(.black).background(Image("history_date_bg").padding(.top, 10))
                LazyVGrid(columns: [GridItem(.flexible(), spacing: 10), GridItem(.flexible(), spacing: 10)], alignment: .leading, spacing: 10) {
                    ForEach(items, id: \.self) { item in
                        HStack(spacing: 6){
                            Image(item.item.icon).resizable().scaledToFit().frame(width: 40, height: 40)
                            Text(item.description).font(.system(size: 11))
                        }.padding(.vertical, 8).padding(.horizontal, 14).background(.white).cornerRadius(8)
                    }
                }.padding(.all, 14).background(Color("#B2E9FF").cornerRadius(12))
            }
        }
    }
}

#Preview {
    NavigationView{
        HistoryView(store: Store.init(initialState: History.State(), reducer: {
            History()
        }))
    }
}
