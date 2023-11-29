//
//  HomeView.swift
//  DrinkingDiary
//
//  Created by yangjian on 2023/11/2.
//

import SwiftUI
import ComposableArchitecture

enum GADShowPosition {
    case drink, charts, reminder
}

struct Home: Reducer {
    struct State: Equatable {
        var root: HomeRoot.State = .init()
        var path: StackState<Path.State> = .init()
        
        mutating func updateDailyState(_ total: Int) {
            root.drink.dailyGoal = total
        }
        mutating func popState() {
            path.removeAll()
        }
        
        mutating func updateRecordState(_ model: Record.Model) {
            if var array = root.drink.recordList {
                array.append(model)
                root.drink.recordList = array
                root.charts.recordList = array
            } else {
                root.drink.recordList = [model]
                root.charts.recordList = [model]
            }
            
        }
    }
    
    enum Action: Equatable {
        case path(StackAction<Path.State, Path.Action>)
        case root(HomeRoot.Action)
        case pushDaily
        case pop
    }
    var body: some Reducer<State, Action> {
        Reduce{ state, action in
            switch action {
            case .pop:
                state.popState()
            case .pushDaily:
                state.path.append(.dailyTarget(.init(total: state.root.drink.goal)))
            case let .root(action):
                switch action {
                case .drink(let action):
                    switch action {
                    case .dailyTargetButtonTapped:
                        return .run { send in
                            await send(.pushDaily)
                        }
                    case .recordButtonTapped:
                        state.path.append(.record(.init()))
                    }
                case let .charts(action):
                    switch action {
                    case .historyButtonTapped:
                        state.path.append(.history(.init()))
                    default:
                        break
                    }
                default:
                    break
                }
            case let .path(action):
                switch action {
                case .element(id: _ ,action: .record(.pop)):
                    state.popState()
                case let .element(id: id, action: .dailyTarget(.pop)):
                    switch state.path[id: id] {
                    case let .dailyTarget(dailyState):
                        state.updateDailyState(dailyState.total)
                        state.popState()
                    default:
                        break
                    }
                case let .element(id: id, action: .record(.saveButtonTapped)):
                    switch state.path[id: id] {
                    case let .record(recordState):
                        state.updateRecordState(recordState.model)
                        return .run { send in
                            await send(.pop)
                        }
                    default:
                        break
                    }
                case .element(id: _, action: .history(.pop)):
                    state.popState()
                default:
                    break
                }
            }
            return .none
        }.forEach(\.path, action: /Action.path) {
            Path()
        }
        
        Scope(state: \.root, action: /Action.root) {
            HomeRoot()
        }
    }
    
    struct Path: Reducer {
        enum State: Equatable {
            case dailyTarget(DailyTarget.State)
            case record(Record.State)
            case history(History.State)
        }
        enum Action: Equatable {
            case dailyTarget(DailyTarget.Action)
            case record(Record.Action)
            case history(History.Action)
        }
        var body: some Reducer<State, Action> {
            Reduce{ state, action in
                return .none
            }
            Scope(state: /State.dailyTarget, action: /Action.dailyTarget) {
                DailyTarget()
            }
            Scope(state: /State.record, action: /Action.record) {
                Record()
            }
            Scope(state: /State.history, action: /Action.history) {
                History()
            }
        }
    }
}

struct HomeView: View {
    let store: StoreOf<Home>
    var body: some View {
        NavigationStackStore(store.scope(state: \.path, action: {.path($0)})) {
            HomeRootView(store: store.scope(state: \.root, action: Home.Action.root))
        } destination: {
            switch $0 {
            case .dailyTarget:
                CaseLet(/Home.Path.State.dailyTarget, action: Home.Path.Action.dailyTarget, then: DailyTargetView.init(store:))
            case .record:
                CaseLet(/Home.Path.State.record, action: Home.Path.Action.record, then: RecordView.init(store:))
            case .history:
                CaseLet(/Home.Path.State.history, action: Home.Path.Action.history, then: HistoryView.init(store:))
            }
        }
    }
}

#Preview {
    HomeView(store: Store.init(initialState: Home.State(), reducer: {
        Home()
    }))
}
