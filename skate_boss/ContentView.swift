//
//  ContentView.swift
//  skate_boss
//
//  Created by Bruce Schwartz on 4/10/23.
//

import SwiftUI

struct ContentView: View {
    @Environment(\.scenePhase) var scenePhase
    @ObservedObject var workoutsModel = WorkoutsModel()
    @State private var lastDate: Date?
    @State private var date: Date = Date()
    @State private var showUpdate = false
    @State private var showEdit = true
    @State private var hasLastDate = false

    init() {
        print("Init Skate Boss content view")
        if let data = UserDefaults.standard.object(forKey: "savedDate") as? Date {
            print("Saved date: \(data)... setting")
            _lastDate = State(initialValue: data)
            hasLastDate = true
        }
        else {
            print("no saved date)")
        }
    }
    
    func formatDate(date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE, MMM dd 'at' h:mm a"
        let dateString = formatter.string(from: lastDate!)
        return dateString
    }
    
    var body: some View {
        VStack {
            Text("Skate Boss")
                .bold()
            Image(uiImage: UIImage(named: "AppIcon") ?? UIImage())
                .resizable()
                .frame(width: 100, height: 100)
                .padding()
            if !workoutsModel.initialized {
                Text("Fetching workout data")
            }
            else if (workoutsModel.noData) {
                Text("No hockey workouts found.")
                    .padding()
                Text("Are you recording your hockey workouts?")
                    .padding()
                Text("Have you given Skate Boss permission to read workout data in Settings->Health->Data Access & Devices?")
                    .padding()
            }
            else {
                // there are two area to display
                // 1. Skate time since last sharpening
                // 2. Sharpen time with update
                if let lastDate = self.lastDate {
                    Text("Hockey since last sharpened:")
                    Text("\(workoutsModel.numWorkouts) sessions")
                    
                    if workoutsModel.workoutDays > 0 {
                        Text("\(workoutsModel.workoutDays) days, \(workoutsModel.workoutDays) hours, \(workoutsModel.workoutMinutes) minutes")
                    }
                    else if workoutsModel.workoutHours > 0 {
                        Text("\(workoutsModel.workoutHours) hours, \(workoutsModel.workoutMinutes) minutes")
                    }
                    else if workoutsModel.workoutMinutes >= 0 {
                        Text("\(workoutsModel.workoutMinutes) minutes")
                    }
                    
                    //date = lastDate
                    let dateString = formatDate(date: lastDate)
                    Text("Sharpened on \(dateString)")
                        .padding()
                }
                else {
                    Text("When were your skates sharpened?")
                        .padding()
                }
                
                if showEdit {
                    Button(action: {
                        showEdit = false
                        date = Date()
//                        if let lastDate = self.lastDate {
//                            date = lastDate
//                        }
                        workoutsModel.getWorkouts(since: lastDate)
                    }) {
                        Text("Edit Sharpen Time")
                    }
                }
                else {
                    Text("Set the date and time of last sharpening")
                    let now = Date()
                    let calendar = Calendar.current
                    let later = calendar.date(byAdding: .day, value: 1, to: now)!
                    DatePicker("", selection: $date, in: ...later, displayedComponents: [.date, .hourAndMinute])
                        .datePickerStyle(.wheel)
                        .onChange(of: date, perform: { value in
                            print("Date changed to \(date)")
                            showUpdate = true
                            hasLastDate = true
                            
                        })
                    HStack {
                        if showUpdate {
                            Button(action: {
                                print("Perform date update")
                                showUpdate = false
                                showEdit = true
                                lastDate = date
                                workoutsModel.getWorkouts(since: lastDate)
                                UserDefaults.standard.set(date, forKey: "savedDate")
                            }) {
                                Text("Update")

                            }
                            Spacer().frame(width: 50)
                        }
                        Button(action: {
                            print("Cancel date update")
                            showUpdate = false
                            showEdit = true
                        }) {
                            Text("Cancel")
                        }
                    }
                }
            }
        }
        .onChange(of: scenePhase) { newPhase in
            if (newPhase == .active) {
                print("skate boss became active")
                workoutsModel.update(since: self.lastDate)
            }
        }

    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
