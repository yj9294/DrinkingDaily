//
//  RecordView.swift
//  DrinkingDiary
//
//  Created by yangjian on 2023/11/6.
//

import SwiftUI

import ComposableArchitecture

struct Record: Reducer {
    struct Model: Codable, Hashable, Equatable {
        var id: String = UUID().uuidString
        var day: String // yyyy-MM-dd
        var time: String // HH:mm
        var item: State.Item // 列别
        var name: String
        var ml: Int // 毫升
        
        var description: String {
            return name + " \(ml)ml"
        }
    }
    
    struct State: Equatable {
        @BindingState var ml: String = "200"
        @BindingState var name: String = "Water"
        var item: Item = .water
        enum Item: String, Equatable, CaseIterable, Codable {
            case water, drinks, milk, coffee, tea, customization
            var icon: String{
                self.rawValue
            }
            var title: String{
                return self.rawValue.capitalized
            }
            var description: String{
                "\(title) 200ml"
            }
        }
        var inputDisable: Bool {
            item != .customization
        }
        var model: Model {
            Model(day: Date().day, time: Date().time, item: item, name: name, ml: Int(ml) ?? 0)
        }
    }
    enum Action: BindableAction, Equatable {
        case binding(BindingAction<State>)
        case pop
        case saveButtonTapped
        case itemButtonTapped(State.Item)
    }
    var body: some Reducer<State, Action> {
        BindingReducer()
        Reduce{ state, action in
            switch action {
            case let .itemButtonTapped(item):
                if state.item == item {
                    return . none
                }
                state.ml = "200"
                state.item = item
                state.name = item.rawValue.capitalized
            default:
                break
            }
            return .none
        }
    }
}

struct RecordView: View {
    let store: StoreOf<Record>
    var body: some View {
        WithViewStore(store, observe: {$0}) { viewStore in
            VStack{
                HStack{Spacer()}
                InputView(store: store)
                ItemsView(store: store)
                Spacer()
            }.toolbar(content: {
                ToolbarItem(placement: .topBarLeading) {
                    Button(action: {
                        viewStore.send(.pop)
                    }, label: {
                        Image("back")
                    })
                }
            }).toolbar(content: {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(action: {
                        viewStore.send(.saveButtonTapped)
                    }, label: {
                        Text("Save").padding(.vertical, 2).padding(.horizontal, 10).font(.system(size: 12.0,weight: .medium))
                    }).foregroundColor(.white).background(Image("record_bg"))
                }
            })
        }.background.navigationTitle(Text("Record")).navigationBarTitleDisplayMode(.inline).navigationBarBackButtonHidden()
    }
    
    struct InputView: View {
        @FocusState var isAction: Bool
        let store: StoreOf<Record>
        var body: some View {
            WithViewStore(store, observe: {$0}) { viewStore in
                HStack{Spacer()}
                VStack(spacing: 0){
                    HStack{
                        TextField("", text: viewStore.$name).multilineTextAlignment(.center).padding(.vertical, 14).padding(.horizontal, 12).background(.white).cornerRadius(8).disabled(viewStore.inputDisable)
                        Spacer()
                    }.padding(.horizontal, 30).padding(.top, 24).padding(.trailing, 100)
                    HStack{
                        HStack{
                            TextField("", text: viewStore.$ml).focused($isAction).multilineTextAlignment(.center).keyboardType(.numberPad)
                            Text("ml")
                        }
                        .padding(.vertical, 14).padding(.horizontal, 12).background(.white).cornerRadius(8)
                        Spacer()
                    }.padding(.horizontal, 30).padding(.bottom, 24).padding(.top, 20).padding(.trailing, 100)
                }.background(Image("record_input_bg").resizable())
            }.padding(.horizontal, 20).padding(.top, 20).toolbar(content: {
                ToolbarItem(placement: .keyboard) {
                    Button("Done") {
                        isAction = false
                    }
                }
            })
        }
    }
    
    struct ItemsView: View {
        let store: StoreOf<Record>
        var body: some View {
            WithViewStore(store, observe: {$0}) { viewStore in
                LazyVGrid(columns: [GridItem(.flexible(), spacing: 10), GridItem(.flexible(), spacing: 10), GridItem(.flexible(), spacing: 10)], content: {
                    ForEach(Record.State.Item.allCases, id: \.self) { item in
                        Button(action: {
                            viewStore.send(.itemButtonTapped(item))
                        }, label: {
                            VStack{
                                Image(item.icon)
                                Text(item.description).font(.system(size: 13))
                            }.foregroundColor(item == viewStore.item ? .blue : .black)
                        })
                    }
                }).padding(.vertical, 10).background(Image("record_item_bg").resizable())
            }.padding(.horizontal, 20).padding(.top, 20)
        }
    }
}

#Preview {
    NavigationView(content: {
        RecordView(store: Store.init(initialState: Record.State(), reducer: {
            Record()
        }))
    })
}
