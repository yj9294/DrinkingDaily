//
//  ReminderView.swift
//  DrinkingDiary
//
//  Created by yangjian on 2023/11/2.
//

import SwiftUI
import ComposableArchitecture

struct Reminder: Reducer {
    struct State: Equatable {
        static func == (lhs: Reminder.State, rhs: Reminder.State) -> Bool {
            lhs.items == rhs.items && lhs.alert == rhs.alert && lhs.date == rhs.date &&
            lhs.ad == rhs.ad
        }
        
        let defaultItems = ["08:00", "10:00", "12:00", "14:00", "16:00", "18:00", "20:00"]
        @UserDefault(key: "reminder:date")
        var items: [String]?
        @PresentationState var alert: AlertState<Action.Alert>?
        @PresentationState var date: DateSelected.State?
        var ad: GADNativeViewModel = .none
        mutating func remove(_ item: String) {
            items  = (items ?? defaultItems).filter({
                $0 != item
            }).sorted(by: { l1, l2 in
                return l1 < l2
            })
        }
        
        mutating func add(_ item: String) {
            items = (items ?? defaultItems).filter({$0 != item})
            items?.append(item)
            items = items?.sorted(by: { l1, l2 in
                return l1 < l2
            })
        }
        
        mutating func alertToDelete(_ item: String) {
            alert = AlertState(title: {
                TextState("Are you sure DELETE?")
            }, actions: {
                ButtonState(role: .cancel) {
                    TextState("Cancel")
                }
                ButtonState(role: .destructive, action: .confirmDeletion(item), label: {
                    TextState("Delete")
                })
            })
        }
        
        mutating func alertToAdd() {
            date = .init()
        }
        
    }
    enum Action: Equatable {
        case alert(PresentationAction<Alert>)
        case date(PresentationAction<DateSelected.Action>)
        case addButtonTapped
        case deleteButtonTapped(String)
        enum Alert: Equatable {
          case confirmDeletion(String)
        }
    }
    var body: some Reducer<State, Action> {
        Reduce{ state, action in
            switch action {
            case let .deleteButtonTapped(item):
                state.alertToDelete(item)
            case .addButtonTapped:
                state.alertToAdd()
            case let .alert(.presented(action)):
                switch action {
                case let .confirmDeletion(item):
                    state.remove(item)
                    NotificationHelper.shared.deleteNotifications(item)
                }
            case let .date(.presented(action)):
                switch action {
                case .cancelButtonTapped:
                    state.date = nil
                case let .dateSaveButtonTapped(date):
                    state.date = nil
                    state.add(date)
                    NotificationHelper.shared.appendReminder(date)
                }
            default:
                break
            }
            return .none
        }.ifLet(\.alert, action: /Action.alert).ifLet(\.$date, action: /Action.date) {
            DateSelected()
        }
    }
}

struct ReminderView: View {
    let store: StoreOf<Reminder>
    var body: some View {
        WithViewStore(store, observe: {$0}) { viewStore in
            VStack{
                ContentView(store: store).padding(.all, 20)
                Spacer()
                if viewStore.ad != .none {
                    HStack{
                        GADNativeView(model: viewStore.ad)
                    }.frame(height: 124).padding(.horizontal, 20).padding(.bottom, 20)
                }
            }.toolbar(content: {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(action: {viewStore.send(.addButtonTapped)}, label: {
                        Image("reminder_add")
                    })
                }
            }).alert(store: store.scope(state: \.$alert, action: { .alert($0) })).fullScreenCover(store: store.scope(state: \.$date, action: { .date($0) })) { store in
                DateSelectedView(store: store).background(PresentationView(.clear)).ignoresSafeArea()
            }
        }.navigationBarTitle(.reminder).background
    }
    
    struct PresentationView: UIViewRepresentable {
        init(_ style: Style = .clear) {
            self.style = style
        }
        let style: Style
        func makeUIView(context: Context) -> UIView {
            if style == .blur {
                let view = UIVisualEffectView(effect: UIBlurEffect(style: .light))
                DispatchQueue.main.async {
                    view.superview?.superview?.backgroundColor = .clear
                }
                return view
            } else {
                let view = UIView()
                DispatchQueue.main.async {
                    view.superview?.superview?.backgroundColor = .clear
                }
                return view
            }
        }

        func updateUIView(_ uiView: UIView, context: Context) {}
        enum Style {
            case clear, blur
        }
    }

    
    struct ContentView: View {
        let store: StoreOf<Reminder>
        var body: some View {
            WithViewStore(store, observe: {$0}) { viewStore in
                ScrollView{
                    LazyVGrid(columns: [GridItem(.flexible())], content: {
                        ForEach(viewStore.items ?? viewStore.defaultItems, id: \.self) { item in
                            HStack{
                                Text(item)
                                Spacer()
                                Button(action: {viewStore.send(.deleteButtonTapped(item))}, label: {
                                    Image("reminder_delete")
                                }).padding(.all, 8)
                            }.padding(.all, 16)
                            Divider().padding(.horizontal, 16)
                        }
                    }).background(.white).cornerRadius(12)
                }
            }
        }
    }
}

struct DateSelected: Reducer {
    struct State: Equatable {}
    enum Action: Equatable {
        case dateSaveButtonTapped(String)
        case cancelButtonTapped
    }
    var body: some Reducer<State, Action> {
        Reduce{ state, action in
            return .none
        }
    }
}

struct DateSelectedView: UIViewRepresentable {
    let store: StoreOf<DateSelected>
    func makeUIView(context: Context) -> some UIView {
        if let view = Bundle.main.loadNibNamed("DateView", owner: nil)?.first as? DateView {
            view.delegate = context.coordinator
           return view
        }
        let dateView = DateView()
        dateView.delegate = context.coordinator
        return dateView
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, DateViewDelegate {
        init(_ preview: DateSelectedView) {
            self.parent = preview
        }
        let parent: DateSelectedView
        
        func completion(time: String) {
            parent.store.send(.dateSaveButtonTapped(time))
        }
        
        func cancel() {
            parent.store.send(.cancelButtonTapped)
        }
    }
    
    func updateUIView(_ uiView: UIViewType, context: Context) {
        
    }
}

#Preview {
    NavigationView(content: {
        ReminderView(store: Store.init(initialState: Reminder.State(), reducer: {
            Reminder()
        }))
    })
}
