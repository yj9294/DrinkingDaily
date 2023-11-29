//
//  LaunchView.swift
//  DrinkingDiary
//
//  Created by yangjian on 2023/11/2.
//

import SwiftUI
import ComposableArchitecture

struct Launch: Reducer {
    enum CancelID { case timer}
    @Dependency(\.continuousClock) var clock
    struct State: Equatable {
        var progress: Double = 0.0
        var duration = 2.5
        var onAppear = true
    }
    enum Action: Equatable {
        case onAppear
        case start
        case stop
        case completion
        case progressing
    }
    
    func reduce(into state: inout State, action: Action) -> Effect<Action> {
        switch action {
        case .start:
            state.progress = 0.0
            state.duration = 2.5
            return .run { send in
                for await _ in clock.timer(interval: .milliseconds(20)) {
                    await send(.progressing)
                }
            }.cancellable(id: CancelID.timer)
        case .progressing:
            debugPrint(state.progress)
            state.progress += 0.02 / state.duration
            if state.progress >= 1.0 {
                state.progress = 1.0
                return .run { send in
                    await send(.stop)
                    await send(.completion)
                }
            }
        case .completion:
            state.onAppear = false
        case .stop:
            return .cancel(id: CancelID.timer)
        default:
            break
        }
        return .none
    }
}

struct LaunchView: View {
    let store: StoreOf<Launch>
    var body: some View {
        WithViewStore(store, observe: {$0}) { viewStore in
            VStack{
                Image("launch_icon").padding(.top, 102)
                Image("launch_title")
                Spacer()
                HStack{
                    ProgressView(value: viewStore.progress).tint(.white)
                }.padding(.horizontal, 85).padding(.bottom, 50)
                HStack{
                    Spacer()
                }.frame(height: 1)
            }.background.onAppear{
                if viewStore.onAppear {
                    viewStore.send(.start)
                }
            }
        }
    }
}

#Preview {
    LaunchView(store: Store.init(initialState: Launch.State(), reducer: {
        Launch()
    }))
}
