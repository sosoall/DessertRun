#!/bin/bash

# 要修复的文件路径
TRANSITION_FILE="Views/Transitions/DessertToExerciseTransition.swift"
WORKOUT_FILE="Views/Exercise/WorkoutCompleteView.swift"

# 创建临时文件
TMP_FILE="tmp_file.swift"

# 删除DessertToExerciseTransition.swift中的重复扩展
echo "正在修复 $TRANSITION_FILE..."
sed '/\/\/ 扩展圆角RoundedCorners/,$d' "$TRANSITION_FILE" > "$TMP_FILE"
mv "$TMP_FILE" "$TRANSITION_FILE"
echo "✅ $TRANSITION_FILE 已修复"

# 删除WorkoutCompleteView.swift中的重复扩展
echo "正在修复 $WORKOUT_FILE..."
sed '/\/\/ 圆角扩展/,$d;/\/\/ 圆角形状/,$d' "$WORKOUT_FILE" > "$TMP_FILE" 
# 如果失败，只保留到最后一个Preview行之前的内容
if ! grep -q "#Preview" "$TMP_FILE"; then
  sed '/struct RoundedCornerShape/,$d' "$WORKOUT_FILE" > "$TMP_FILE"
  echo "#Preview {
    NavigationStack {
        WorkoutCompleteView(
            workoutSession: {
                let dessert = DessertData.getSampleDesserts().first!
                let exerciseType = ExerciseTypeData.getSampleExerciseTypes().first!
                let session = WorkoutSession(targetDessert: dessert, exerciseType: exerciseType)
                session.totalElapsedSeconds = 1200 // 20分钟
                session.burnedCalories = 240 // 80%完成
                session.distanceInMeters = 2500 // 2.5公里
                return session
            }()
        )
        .environmentObject(AppState.shared)
    }
}" >> "$TMP_FILE"
fi
mv "$TMP_FILE" "$WORKOUT_FILE"
echo "✅ $WORKOUT_FILE 已修复"

echo "所有文件已修复完成。请在Xcode中重新构建项目。" 