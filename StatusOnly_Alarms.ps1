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

$InstName = (GetEC2InstanceName ($InstID))
$AlarmArn = "arn:aws:sns:us-west-2:978166019371:$Topic"

# Status Check
Write-CWMetricAlarm `
    -AlarmName "Test-$Account-$InstName-Status" `
    -AlarmDescription "Any Status Check Failed" `
    -ActionsEnabled 0 `
    -AlarmAction $AlarmArn `
    -ComparisonOperator GreaterThanThreshold `
    -Dimension @{name="InstanceId"; Value=$InstID}`
    -EvaluationPeriod 2 `
    -MetricName "StatusCheckFailed" `
    -Namespace "AWS/EC2" `
    -Period 60 `
    -Statistic "Average" `
    -Threshold 1
