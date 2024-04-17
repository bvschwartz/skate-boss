//
//  workouts.swift
//  
//
//  Created by Bruce Schwartz on 4/10/23.
//

import Foundation
import HealthKit

final class WorkoutsModel: ObservableObject {
    @Published var numWorkouts: Int = 0
    @Published var workoutTotalSeconds: Int = 0
    @Published var workoutDays: Int = 0
    @Published var workoutHours: Int = 0
    @Published var workoutMinutes: Int = 0
    @Published var oldestDate: Date? = nil
    @Published var initialized = false
    @Published var noData = false

    
    init() {
    }
    
    func update(since: Date?) {
        self.getWorkouts(since: since)
    }
    
    func getWorkouts(since: Date?) {
        
        let healthStore = HKHealthStore()
        let workoutType = HKObjectType.workoutType()
        let allTypes = Set([workoutType])
        print("getWorkouts: is health kit data avialable:", HKHealthStore.isHealthDataAvailable())
        
        let status = healthStore.authorizationStatus(for: workoutType)
        switch status {
        case .notDetermined:
            print("Authorization status not determined")
        case .sharingDenied:
            print("Authorization status denied")
            //return
        case .sharingAuthorized:
            print("Authorization status authorized")
        default:
            print("Unknown authorization status")
        }


        healthStore.requestAuthorization(toShare: [], read: allTypes) { (success, error) in
            if !success {
                print("Authorization denied for workout data. Error: \(error?.localizedDescription ?? "Unknown error")")
                return
            }
            print("Access is authorized for workout data", success)
            
            // Create a predicate to query workouts from the last week
    //        let startDate = Calendar.current.date(byAdding: .day, value: -7, to: Date())!
    //        let endDate = Date()
    //        let predicate = HKQuery.predicateForSamples(withStart: startDate, end: endDate, options: .strictEndDate)
            
            // Create a query to retrieve all workouts within the specified time frame
            var predicate: NSPredicate? = nil
            if (since != nil) {
                predicate = HKQuery.predicateForSamples(withStart: since, end: nil)
            }
            let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: false)
            let query = HKSampleQuery(sampleType: workoutType, predicate: predicate, limit: 100, sortDescriptors: [sortDescriptor]) { (query, samples, error) in
                
                //let query = HKSampleQuery(sampleType: workoutType, predicate: predicate, limit: HKObjectQueryNoLimit, sortDescriptors: nil) { (query, samples, error) in
                if let error = error {
                    print("Error retrieving workouts: \(error.localizedDescription)")
                    return
                }
                
                // Process the retrieved workouts
                guard let workouts = samples as? [HKWorkout] else {
                    print("Unexpected sample type")
                    return
                }
                
                var count = 0
                var totalDuration : TimeInterval = 0.0
                var oldestDate: Date? = nil
                for workout in workouts {
                    // Access workout data such as duration, distance, and energy burned
                    let duration = workout.duration
//                    let distance = workout.totalDistance?.doubleValue(for: HKUnit.meter())
//                    let energyBurned = workout.totalEnergyBurned?.doubleValue(for: HKUnit.kilocalorie())
                    let started = workout.startDate
                    let rawValue = UInt(workout.workoutActivityType.rawValue)
                    guard let workoutActivityType = HKWorkoutActivityType(rawValue: rawValue) else {
                        print("Unknown workout activity type:", rawValue)
                        continue
                    }
                    if (workoutActivityType != .hockey) {
                        continue
                    }
                    //print("Hockey!!! started: \(started), duration: \(duration), distance: \(distance ?? 0), energy burned: \(energyBurned ?? 0)")
                    count += 1
                    totalDuration += duration
                    oldestDate = started
                }
                let totalSeconds = Int(totalDuration)
                let days = totalSeconds / (3600 * 24)
                let hours = (totalSeconds - (days * 3600 * 24)) / 3600
                let minutes = (totalSeconds - (days * (3600 * 24)) - (hours * 3600)) / 60
                DispatchQueue.main.async {
                    // Update UI here
                    self.numWorkouts = count
                    self.workoutTotalSeconds = totalSeconds
                    self.workoutDays = days
                    self.workoutHours = hours
                    self.workoutMinutes = minutes
                    self.oldestDate = oldestDate
                    self.initialized = true
                    self.noData = false

                }
                
                print("got \(count) workout records, total duration: \(days):\(hours):\(minutes)  (\(totalSeconds) seconds)")
                
                if (totalSeconds == 0) {
                    print("check for any data at all")
                    // check to see if there is any data at all
                    let query = HKSampleQuery(sampleType: workoutType, predicate: nil, limit: 1, sortDescriptors: [sortDescriptor]) { (query, samples, error) in
                        print("HKSampleQuery returns!")
                        if let samples = samples {
                            print("samples count: \(samples.count)")
                            if samples.count == 0 {
                                DispatchQueue.main.async {
                                    self.noData = true
                                }
                            }
                        }
                        else {
                            print("no samples returned")
                        }
                    }
                    // Execute the query
                    HKHealthStore().execute(query)

                }
            }
            
            // Execute the query
            HKHealthStore().execute(query)
        }

    }

}
    
extension HKWorkoutActivityType {

    /*
     Simple mapping of available workout types to a human readable name.
     According to GPT this should be avialble as the .name of an activity type
     */
    var name: String {
        switch self {
        case .americanFootball:             return "American Football"
        case .archery:                      return "Archery"
        case .australianFootball:           return "Australian Football"
        case .badminton:                    return "Badminton"
        case .baseball:                     return "Baseball"
        case .basketball:                   return "Basketball"
        case .bowling:                      return "Bowling"
        case .boxing:                       return "Boxing"
        case .climbing:                     return "Climbing"
        case .crossTraining:                return "Cross Training"
        case .curling:                      return "Curling"
        case .cycling:                      return "Cycling"
        case .dance:                        return "Dance"
        case .danceInspiredTraining:        return "Dance Inspired Training"
        case .elliptical:                   return "Elliptical"
        case .equestrianSports:             return "Equestrian Sports"
        case .fencing:                      return "Fencing"
        case .fishing:                      return "Fishing"
        case .functionalStrengthTraining:   return "Functional Strength Training"
        case .golf:                         return "Golf"
        case .gymnastics:                   return "Gymnastics"
        case .handball:                     return "Handball"
        case .hiking:                       return "Hiking"
        case .hockey:                       return "Hockey"
        case .hunting:                      return "Hunting"
        case .lacrosse:                     return "Lacrosse"
        case .martialArts:                  return "Martial Arts"
        case .mindAndBody:                  return "Mind and Body"
        case .mixedMetabolicCardioTraining: return "Mixed Metabolic Cardio Training"
        case .paddleSports:                 return "Paddle Sports"
        case .play:                         return "Play"
        case .preparationAndRecovery:       return "Preparation and Recovery"
        case .racquetball:                  return "Racquetball"
        case .rowing:                       return "Rowing"
        case .rugby:                        return "Rugby"
        case .running:                      return "Running"
        case .sailing:                      return "Sailing"
        case .skatingSports:                return "Skating Sports"
        case .snowSports:                   return "Snow Sports"
        case .soccer:                       return "Soccer"
        case .softball:                     return "Softball"
        case .squash:                       return "Squash"
        case .stairClimbing:                return "Stair Climbing"
        case .surfingSports:                return "Surfing Sports"
        case .swimming:                     return "Swimming"
        case .tableTennis:                  return "Table Tennis"
        case .tennis:                       return "Tennis"
        case .trackAndField:                return "Track and Field"
        case .traditionalStrengthTraining:  return "Traditional Strength Training"
        case .volleyball:                   return "Volleyball"
        case .walking:                      return "Walking"
        case .waterFitness:                 return "Water Fitness"
        case .waterPolo:                    return "Water Polo"
        case .waterSports:                  return "Water Sports"
        case .wrestling:                    return "Wrestling"
        case .yoga:                         return "Yoga"

        // iOS 10
        case .barre:                        return "Barre"
        case .coreTraining:                 return "Core Training"
        case .crossCountrySkiing:           return "Cross Country Skiing"
        case .downhillSkiing:               return "Downhill Skiing"
        case .flexibility:                  return "Flexibility"
        case .highIntensityIntervalTraining:    return "High Intensity Interval Training"
        case .jumpRope:                     return "Jump Rope"
        case .kickboxing:                   return "Kickboxing"
        case .pilates:                      return "Pilates"
        case .snowboarding:                 return "Snowboarding"
        case .stairs:                       return "Stairs"
        case .stepTraining:                 return "Step Training"
        case .wheelchairWalkPace:           return "Wheelchair Walk Pace"
        case .wheelchairRunPace:            return "Wheelchair Run Pace"

        // iOS 11
        case .taiChi:                       return "Tai Chi"
        case .mixedCardio:                  return "Mixed Cardio"
        case .handCycling:                  return "Hand Cycling"

        // iOS 13
        case .discSports:                   return "Disc Sports"
        case .fitnessGaming:                return "Fitness Gaming"

        // Catch-all
        default:                            return "Other"
        }
    }

}



