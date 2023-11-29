//
//  ChartsView.swift
//  DrinkingDiary
//
//  Created by yangjian on 2023/11/2.
//

import SwiftUI
import ComposableArchitecture

struct Charts: Reducer {
    struct Model: Codable, Hashable, Identifiable {
        var id: String = UUID().uuidString
        var displayProgerss: CGFloat = 0.0
        var progress: CGFloat
        var totalML: Int
        var unit: String // 描述 类似 9:00 或者 Mon  或者03/01 或者 Jan
    }
    
    struct State: Equatable {
        static func == (lhs: Charts.State, rhs: Charts.State) -> Bool {
            lhs.top == rhs.top &&
            lhs.left == rhs.left &&
            lhs.right == rhs.right
        }
        
        @UserDefault(key: "record:list")
        var recordList: [Record.Model]?
        var top: Top.State = .init()
        var left: Left.State = .init()
        var right: Right.State = .init()
        
        mutating func updateLeftItems(_ item: Top.State.Item) {
            var target: [String] = []
            let source = left.source
            switch item {
            case .day:
                 target = source.map({
                    "\($0 * 200)"
                })
            case .week, .month:
                target = source.map({
                   "\($0 * 500)"
               })
            case .year:
                target = source.map({
                   "\($0 * 500 * 30)"
               })
            }
            left.items = target.reversed()
        }
        
        mutating func updateRightItems(_ item: Top.State.Item) {
            var max = 1
            // 数据源
            let recordList: [Record.Model] = recordList ?? []
            // 用于计算进度
            max = left.items.map({Int($0) ?? 0}).max { l1, l2 in
                l1 < l2
            } ?? 1
            var array: [Model] = []
            switch item {
            case .day:
                array = item.unit.map({ time in
                    let total = recordList.filter { model in
                        let modelTime = model.time.components(separatedBy: ":").first ?? "00"
                        let nowTime = time.components(separatedBy: "-").first ?? "00"
                        return Date().day == model.day && (Int(modelTime)! >= Int(nowTime)!) && (Int(modelTime)! < Int(nowTime)! + 6)
                    }.map({
                        $0.ml
                    }).reduce(0, +)
                    return Model(progress: Double(total)  / Double(max) , totalML: total, unit: time)
                })
            case .week:
                array = item.unit.map { weeks in
                    // 当前搜索目的周几 需要从周日开始作为下标0开始的 所以 unit数组必须是7123456
                    let week = Top.State.Item.allCases.filter {
                        $0 == .week
                    }.first?.unit.firstIndex(of: weeks) ?? 0
                    
                    // 当前日期 用于确定当前周
                    let weekDay = Calendar.current.component(.weekday, from: Date())
                    let firstCalendar = Calendar.current.date(byAdding: .day, value: 1-weekDay, to: Date()) ?? Date()
                    let dateFormatter = DateFormatter()
                    dateFormatter.dateFormat = "yyyy-MM-dd"
                            
                    // 目标日期
                    let target = Calendar.current.date(byAdding: .day, value: week, to: firstCalendar) ?? Date()
                    let targetString = dateFormatter.string(from: target)
                    
                    let total = recordList.filter { model in
                        model.day == targetString
                    }.map({
                        $0.ml
                    }).reduce(0, +)
                    return Model(progress: Double(total)  / Double(max), totalML: total, unit: weeks)
                }
            case .month:
                array = item.unit.reversed().map { date in
                    let year = Calendar.current.component(.year, from: Date())
                    
                    let month = date.components(separatedBy: "/").first ?? "01"
                    let day = date.components(separatedBy: "/").last ?? "01"
                    
                    let total = recordList.filter { model in
                        return model.day == "\(year)-\(month)-\(day)"
                    }.map({
                        $0.ml
                    }).reduce(0, +)
                    
                    return Model(progress: Double(total)  / Double(max), totalML: total, unit: date)

                }
            case .year:
                array =  item.unit.reversed().map { month in
                    let total = recordList.filter { model in
                        let formatter = DateFormatter()
                        formatter.dateFormat = "yyyy-MM-dd"
                        let date = formatter.date(from: model.day)
                        formatter.dateFormat = "MMM"
                        let m = formatter.string(from: date!)
                        return m == month
                    }.map({
                        $0.ml
                    }).reduce(0, +)
                    return Model(progress: Double(total)  / Double(max), totalML: total, unit: month)

                }
            }
            right.items = array
        }
    }
    enum Action: Equatable {
        case historyButtonTapped
        case top(Top.Action)
        case left(Left.Action)
        case right(Right.Action)
    }
    var body: some Reducer<State, Action> {
        Reduce{ state, action in
            switch action {
            case let .top(action):
                switch action{
                case let .itemButtonTapped(item):
                    state.updateLeftItems(item)
                    state.updateRightItems(item)
                }
            default:
                break
            }
            return .none
        }
        
        Scope.init(state: \.top, action: /Action.top) {
            Top()
        }
        Scope.init(state: \.left, action: /Action.left) {
            Left()
        }
        Scope.init(state: \.right, action: /Action.right) {
            Right()
        }
    }
    
    struct Top: Reducer {
        struct State: Equatable {
            var item = Item.day
            let items = Item.allCases
            enum Item: String, CaseIterable {
                case day, week, month, year
                var title: String {
                    self.rawValue.capitalized
                }
                var unit: [String] {
                    switch self {
                    case .day:
                        return ["0-6", "6-12", "12-18", "18-24"]
                    case .week:
                        return ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]
                    case .month:
                        var days: [String] = []
                        for index in 0..<30 {
                            let formatter = DateFormatter()
                            formatter.dateFormat = "MM/dd"
                            let date = Date(timeIntervalSinceNow: TimeInterval(index * 24 * 60 * 60 * -1))
                            let day = formatter.string(from: date)
                            days.insert(day, at: 0)
                        }
                        return days
                    case .year:
                        var months: [String] = []
                        for index in 0..<12 {
                            let d = Calendar.current.date(byAdding: .month, value: -index, to: Date()) ?? Date()
                            let formatter = DateFormatter()
                            formatter.dateFormat = "MMM"
                            let day = formatter.string(from: d)
                            months.insert(day, at: 0)
                        }
                        return months
                    }
                }
            }
        }
        enum Action: Equatable {
            case itemButtonTapped(State.Item)
        }
        var body: some Reducer<State, Action> {
            Reduce{ state, action in
                switch action {
                case let .itemButtonTapped(item):
                    state.item = item
                }
                return .none
            }
        }
    }
    
    struct Left: Reducer {
        struct State: Equatable {
            var source: [Int] = Array(0...7)
            var items: [String] = []
        }
        enum Action: Equatable {}
        var body: some Reducer<State, Action> {
            Reduce{ state, action in
                return .none
            }
        }
    }
    
    struct Right: Reducer {
        struct State: Equatable {
            var items: [Model] = []
        }
        enum Action: Equatable {}
        var body: some Reducer<State, Action> {
            Reduce{ state, action in
                return .none
            }
        }
    }

}

struct ChartsView: View {
    let store: StoreOf<Charts>
    var body: some View {
        WithViewStore(store, observe: {$0}) { viewStore in
            VStack{
                HStack{Spacer()}
                VStack{
                    ScrollView{
                        ContentView(store: store)
                    }
                }.padding(.horizontal, 20).padding(.top, 32)
                Spacer()
            }.background.toolbar(content: {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(action: {viewStore.send(.historyButtonTapped)}, label: {
                        Image("record_history")
                    })
                }
            })
        }.navigationBarTitle(.charts)
    }
    
    struct ContentView: View {
        let store: StoreOf<Charts>
        var body: some View {
            VStack(spacing: 0){
                TopView(store: store.scope(state: \.top, action: Charts.Action.top))
                LeftView(store: store.scope(state: \.left, action: Charts.Action.left)).overlay {
                    RightView(store: store.scope(state: \.right, action: Charts.Action.right))
                }.background(.white)
            }.cornerRadius(12)
        }
        
        struct TopView: View {
            let store: StoreOf<Charts.Top>
            var body: some View {
                WithViewStore(store, observe: {$0}) { viewStore in
                    HStack{
                        Spacer()
                        ForEach(viewStore.items, id:\.self) { item in
                            Button(action: {viewStore.send(.itemButtonTapped(item))}, label: {
                                VStack(spacing: 3){
                                    Text(item.title).font(.system(size: 14, weight: .medium)).underline(item == viewStore.item, color: Color("#00BEFF"))
                                }
                            }).padding(.all, 16).foregroundStyle(Color(item == viewStore.item ? "#00BEFF" : "#A6BFC8"))
                        }
                        Spacer()
                    }.onAppear{
                        viewStore.send(.itemButtonTapped(.day))
                    }
                }.background(Color("#D4F4FF"))
            }
        }
        
        struct LeftView: View {
            let store: StoreOf<Charts.Left>
            var body: some View {
                WithViewStore(store, observe: {$0}) { viewStore in
                    HStack(alignment: .top, spacing: 1){
                        VStack(spacing:0){
                            ForEach(viewStore.items, id: \.self) { item in
                                HStack{
                                    Spacer()
                                    Text(item).multilineTextAlignment(.trailing).font(.system(size: 12)).foregroundStyle(Color("#A6BFC8"))
                                    Color("#A6BFC8").frame(width: 6, height: 1)
                                }.padding(.vertical, 14).frame(maxWidth: 70).lineLimit(1)
                            }
                        }.background(.white)
                        
                        VStack(spacing:0){
                            ForEach(viewStore.items, id: \.self) { item in
                                ZStack{
                                    Text(item).font(.system(size: 12)).opacity(0)
                                    Color("#E5EDF0").frame(height: 1)
                                }.padding(.vertical, 14).lineLimit(1).padding(.leading, 20)
                            }
                        }.background(.white)
                    }.background(Color("#E5EDF0").padding(.vertical, 20))
                }.padding(.bottom, 50)
            }
        }
        
        struct RightView: View {
            let store: StoreOf<Charts.Right>
            var body: some View {
                WithViewStore(store, observe: {$0}) { viewStore in
                    HStack{
                        ScrollView(.horizontal) {
                            VStack(spacing: 0){
                                HStack(spacing: 20){
                                    ForEach(viewStore.items) { item in
                                        VStack{
                                            GeometryReader{ proxy in
                                                VStack(spacing: 0){
                                                    Color.clear.frame(height: proxy.size.height * (1-item.progress))
                                                    LinearGradient(colors: [Color("#E7FF58"), Color("#21EBBB")], startPoint: .top, endPoint: .bottom).cornerRadius(4)
                                                }.frame(width: 30)
                                            }
                                        }.frame(width: 30).padding(.top, 20)
                                    }
                                    Spacer()
                                }
                                HStack(spacing: 20){
                                    ForEach(viewStore.items) { item in
                                        Text(item.unit).font(.system(size: 10)).frame(width: 30, height: 70)
                                    }
                                    Spacer()
                                }
                            }.padding(.leading, 94)
                        }
                    }
                }
            }
        }
    }
}

#Preview {
    NavigationView(content: {
        ChartsView(store: Store.init(initialState: Charts.State(), reducer: {
            Charts()
        }))
    })
}

#Preview {
    ChartsView.ContentView.LeftView(store: Store(initialState: Charts.Left.State(), reducer: {
        Charts.Left()
    }))
}

#Preview {
    ChartsView.ContentView.RightView(store: Store(initialState: Charts.Right.State(items: [Charts.Model(progress: 0.33, totalML: 1700, unit: "14:00")]), reducer: {
        Charts.Right()
    }))
}
