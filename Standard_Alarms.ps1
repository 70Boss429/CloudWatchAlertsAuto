Param(
    $InstID = "i-0aa03524aca4c88f7",
    $Account = "Master",
    $Topic = "SamSmith"
)

function GetEC2InstanceName ($InstID) 
{
$tags = (Get-EC2Instance).RunningInstance | Where-Object {$_.instanceId -eq $InstID} | select Tag
$tagName = $tags.Tag | Where-Object {$_.Key -eq "Name"} | select -ExpandProperty Value
return $tagName
}

$vols = @(get-ec2volume) | ? { $_.Attachments.InstanceId -eq $InstID}
$volIds = $vols | % { $_.VolumeId}

$InstName = (GetEC2InstanceName ($InstID))
$AlarmArn = "arn:aws:sns:us-west-2:ACCT#:$Topic"

# Network Outbound Alarm
Write-CWMetricAlarm `
    -AlarmName "Test-$Account-$InstName-NetworkOut" `
    -AlarmDescription "Outbound Network Traffic" `
    -ActionsEnabled 1 `
    -AlarmAction $AlarmArn `
    -ComparisonOperator GreaterThanThreshold `
    -Dimension @{name="InstanceId"; Value=$InstID}`
    -EvaluationPeriod 2 `
    -MetricName "NetworkOut" `
    -Namespace "AWS/EC2" `
    -Period 300 `
    -Statistic "Average" `
    -Threshold 1.0E7 `
    -Unit Bytes

# Network Inbound Alarm
Write-CWMetricAlarm `
    -AlarmName "Test-$Account-$InstName-NetworkIn" `
    -AlarmDescription "Inbound Network Traffic" `
    -ActionsEnabled 1 `
    -AlarmAction $AlarmArn `
    -ComparisonOperator GreaterThanThreshold `
    -Dimension @{name="InstanceId"; Value=$InstID}`
    -EvaluationPeriod 2 `
    -MetricName "NetworkIn" `
    -Namespace "AWS/EC2" `
    -Period 300 `
    -Statistic "Average" `
    -Threshold 1.0E7 `
    -Unit Bytes

# CPU Utilization Alarm
Write-CWMetricAlarm `
    -AlarmName "Test-$Account-$InstName-CPU-Utilization" `
    -AlarmDescription "% CPU Utilization" `
    -ActionsEnabled 1 `
    -AlarmAction $AlarmArn `
    -ComparisonOperator GreaterThanThreshold `
    -Dimension @{name="InstanceId"; Value=$InstID}`
    -EvaluationPeriod 2 `
    -MetricName "CPUUtilization" `
    -Namespace "AWS/EC2" `
    -Period 300 `
    -Statistic "Average" `
    -Threshold 10

# Status Check
Write-CWMetricAlarm `
    -AlarmName "Test-$Account-$InstName-Status" `
    -AlarmDescription "Any Status Check Failed" `
    -ActionsEnabled 1 `
    -AlarmAction $AlarmArn `
    -ComparisonOperator GreaterThanThreshold `
    -Dimension @{name="InstanceId"; Value=$InstID}`
    -EvaluationPeriod 2 `
    -MetricName "StatusCheckFailed" `
    -Namespace "AWS/EC2" `
    -Period 60 `
    -Statistic "Average" `
    -Threshold 1

# Disk Queue Length
Foreach ($vol in $volIds)
    {
    Write-CWMetricAlarm `
       -AlarmName "Test-$Account-$InstName-$vol-DiskQueueLength" `
       -AlarmDescription "Disk Queueu Length" `
       -ActionsEnabled 1 `
       -AlarmAction $AlarmArn `
       -ComparisonOperator GreaterThanOrEqualToThreshold `
       -Dimension @{name="VolumeId"; Value=$vol}`
       -EvaluationPeriod 1 `
       -MetricName "VolumeQueueLength" `
       -Namespace "AWS/EBS" `
       -Period 300 `
       -Statistic "Average" `
       -Threshold 0.05
    }
