//
//  ContentView.swift
//  DrinkingDiary
//
//  Created by yangjian on 2023/11/2.
//

import SwiftUI
import ComposableArchitecture

struct Root: Reducer {
    struct State: Equatable {
        var launch: Launch.State = .init()
        var home: Home.State = .init()
        var item: Item = .launch
        var isBackground = false
        enum Item {
            case home, launch
        }
    }
    enum Action: Equatable {
        case launch(Launch.Action)
        case home(Home.Action)
        case background(Bool)
    }
    var body: some Reducer<State, Action> {
        Reduce{ state, action in
            switch action {
            case let .background(bool):
                state.isBackground = bool
            case let .launch(action):
                switch action {
                case .onAppear:
                    state.item = .launch
                case .completion:
                    if !state.isBackground {
                        state.item = .home
                    }
                default:
                    break
                }
            default:
                break
            }
            return .none
        }
        Scope.init(state: \.launch, action: /Action.launch) {
            Launch()
        }
        Scope.init(state: \.home, action: /Action.home) {
            Home()
        }
    }
}

struct RootView: View {
    @Environment(\.scenePhase) var scenePhase
    let store: StoreOf<Root>
    var body: some View {
        WithViewStore(store, observe: {$0}) { viewStore in
            TabView(selection: .constant(viewStore.item),
                    content:  {
                LaunchView(store: store.scope(state: \.launch, action: Root.Action.launch)).tag(Root.State.Item.launch)
                HomeView(store: store.scope(state: \.home, action: Root.Action.home)).tag(Root.State.Item.home)
            }).onReceive(NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification), perform: { _ in
                if viewStore.isBackground {
                    viewStore.send(.launch(.onAppear))
                    viewStore.send(.launch(.start))
                }
                viewStore.send(.background(false))
            }).onReceive(NotificationCenter.default.publisher(for: UIApplication.didEnterBackgroundNotification), perform: { _ in
                viewStore.send(.background(true))
                viewStore.send(.launch(.stop))
                viewStore.send(.launch(.dismissInterestialAD))
            })
        }
    }
}

#Preview {
    RootView(store: Store.init(initialState: Root.State(), reducer: {
        Root()
    }))
}
