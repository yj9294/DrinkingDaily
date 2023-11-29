//
//  HomeRootView.swift
//  DrinkingDiary
//
//  Created by yangjian on 2023/11/2.
//

import SwiftUI
import GADUtil
import ComposableArchitecture

struct HomeRoot: Reducer {
    struct State: Equatable {
        @BindingState var item: Item = .drink
        var drink: Drink.State = .init()
        var charts: Charts.State = .init()
        var reminder: Reminder.State = .init()
        var drinkImpressionDate: Date = .init(timeIntervalSinceNow: -11)
        var chartsImpressionDate: Date = .init(timeIntervalSinceNow: -11)
        var reminderImpressionDate: Date = .init(timeIntervalSinceNow: -11)
        var isAllowImpressionDrink: Bool {
            if Date().timeIntervalSince(drinkImpressionDate) <= 10 {
                debugPrint("[ad] drink native ad 间隔小于10秒 ")
                return false
            } else {
                return true
            }
        }
        var isAllowImpressionCharts: Bool {
            if Date().timeIntervalSince(chartsImpressionDate) <= 10 {
                debugPrint("[ad] charts native ad 间隔小于10秒 ")
                return false
            } else {
                return true
            }
        }
        var isAllowImpressionReminder: Bool {
            if Date().timeIntervalSince(reminderImpressionDate) <= 10 {
                debugPrint("[ad] reminder native ad 间隔小于10秒 ")
                return false
            } else {
                return true
            }
        }
        enum Item: String, CaseIterable {
            case drink, charts, reminder
            var icon: String {
                self.rawValue
            }
            var titleIcon: String{
                self.rawValue + "_title"
            }
            var selectedIcon: String {
                self.rawValue + "_selected"
            }
        }
    }
    enum Action: BindableAction, Equatable {
        case binding(BindingAction<State>)
        case drink(Drink.Action)
        case charts(Charts.Action)
        case reminder(Reminder.Action)
        
        case loadingAD(GADShowPosition = .drink)
        case cleanAD
        case updateAD(GADNativeViewModel?, GADShowPosition = .drink)
    }
    var body: some Reducer<State, Action> {
        BindingReducer()
        Reduce{ state, action in
            switch action {
            case let .loadingAD(postion):
                return .run { send in
                    do {
                        _ = try await GADUtil.share.load(.native)
                        let model = await GADUtil.share.show(.native) as? GADNativeModel
                        await send(.updateAD(.init(model: model), postion))
                    } catch let err {
                        if (err as? GADPreloadError) != .loading {
                            await send(.updateAD(nil, postion))
                        }
                    }
                }
            case let .updateAD(model, postion):
                switch postion {
                case .drink:
                    if let model = model, state.isAllowImpressionDrink {
                        state.drink.ad = model
                        state.drinkImpressionDate = Date()
                    }
                case .charts:
                    if let model = model, state.isAllowImpressionCharts{
                        state.charts.ad = model
                        state.chartsImpressionDate = Date()
                    }
                case .reminder:
                    if let model = model, state.isAllowImpressionReminder {
                        state.reminder.ad = model
                        state.reminderImpressionDate = Date()
                    }
                }
                
                if model == nil {
                    state.reminder.ad = .none
                    state.charts.ad = .none
                    state.drink.ad = .none
                }
                
            case .cleanAD:
                GADUtil.share.disappear(.native)
                return .run{ send in
                    await send(.updateAD(nil))
                }
            default:
                break
            }
            return .none
        }
        Scope(state: \.drink, action: /Action.drink) {
            Drink()
        }
        Scope(state: \.charts, action: /Action.charts) {
            Charts()
        }
        Scope(state: \.reminder, action: /Action.reminder) {
            Reminder()
        }
    }
}

struct HomeRootView: View {
    let store: StoreOf<HomeRoot>
    var body: some View {
        WithViewStore(store, observe: {$0}) { viewStore in
            VStack{
                HomeContentView(store: store)
                HStack{
                    HomeTabBarView(selectedItem: viewStore.$item)
                }.padding(.horizontal, 50)
            }.background
        }
    }
}

struct HomeContentView: View {
    let store: StoreOf<HomeRoot>
    var body: some View {
        WithViewStore(store, observe: {$0}) { viewStore in
            VStack{
                switch viewStore.item {
                case .drink:
                    DrinkView(store: store.scope(state: \.drink, action: HomeRoot.Action.drink)).onAppear{
                        debugPrint("----drink 出现")
                        viewStore.send(.cleanAD)
                        viewStore.send(.loadingAD(.drink))
                    }
                case .charts:
                    ChartsView(store: store.scope(state: \.charts, action: HomeRoot.Action.charts)).onAppear{
                        debugPrint("----charts 出现")
                        viewStore.send(.cleanAD)
                        viewStore.send(.loadingAD(.charts))

                    }
                case .reminder:
                    ReminderView(store: store.scope(state: \.reminder, action: HomeRoot.Action.reminder)).onAppear{
                        debugPrint("----reminder 出现")
                        viewStore.send(.cleanAD)
                        viewStore.send(.loadingAD(.reminder))

                    }
                }
            }
        }
    }
}

struct HomeTabBarView: View {
    @Binding var selectedItem: HomeRoot.State.Item
    var items = HomeRoot.State.Item.allCases
    var body: some View {
        ForEach(items, id: \.self) { ele in
            Button(action: {
                selectedItem = ele
            }, label: {
                HStack {
                    Spacer()
                    Image( ele == selectedItem ? ele.selectedIcon : ele.icon)
                    Spacer()
                }.padding(.vertical, 8)
            })
        }
    }
}

#Preview {
    NavigationView(content: {
        HomeRootView(store: Store.init(initialState: HomeRoot.State(), reducer: {
            HomeRoot()
        }))
    })
}
