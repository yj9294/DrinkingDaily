//
//  LaunchView.swift
//  DrinkingDiary
//
//  Created by yangjian on 2023/11/2.
//

import SwiftUI
import GADUtil
import ComposableArchitecture

struct Launch: Reducer {
    enum CancelID { case timer}
    @Dependency(\.continuousClock) var clock
    struct State: Equatable {
        var progress: Double = 0.0
        var duration = 12.5
        var onAppear = true
    }
    enum Action: Equatable {
        case onAppear
        case start
        case stop
        case completion
        case progressing
        case loadInterestialAD
        case updateDuration
        case showInterestialAD
        case dismissInterestialAD
    }
    
    func reduce(into state: inout State, action: Action) -> Effect<Action> {
        switch action {
        case .start:
            state.progress = 0.0
            state.duration = 12.5
            return .run { send in
                for await _ in clock.timer(interval: .milliseconds(20)) {
                    await send(.progressing)
                    if GADUtil.share.isLoaded(.interstitial) {
                        await send(.updateDuration)
                    }
                }
            }.cancellable(id: CancelID.timer)
        case .progressing:
            debugPrint(state.progress)
            state.progress += 0.02 / state.duration
            if state.progress >= 1.0 {
                state.progress = 1.0
                return .run { send in
                    await send(.stop)
                    await send(.showInterestialAD)
                }
            }
        case .loadInterestialAD:
            GADUtil.share.load(.interstitial)
            GADUtil.share.load(.native)
        case .showInterestialAD:
            return .run { send in
                await GADUtil.share.show(.interstitial)
                await send(.completion)
            }
        case .completion:
            state.onAppear = false
        case .updateDuration:
            if state.progress > 0.23 {
                state.duration = 0.25
            }
        case .stop:
            return .cancel(id: CancelID.timer)
        case .dismissInterestialAD:
            return .run { send in
                await GADUtil.share.dismiss()
            }
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
                    viewStore.send(.loadInterestialAD)
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
