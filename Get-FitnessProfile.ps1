<#
.Synopsis
    Calculate fitness profile for FORCE Evaluation
.DESCRIPTION
    
.EXAMPLE
    Get-FitnessProfile -Ages 18, 29, 35, 40
.EXAMPLE
    Get-FitnessProfile -Ages 18..65
.INPUTS
    Inputs to this cmdlet (if any)
.OUTPUTS
    Hashtable of values calculated
#>
function Get-FitnessProfile
{
    [CmdletBinding(SupportsShouldProcess=$true, 
                    PositionalBinding=$false)]
    [Alias()]
    [OutputType([PSCustomObject])]
    Param
    (
        # Enter an age range to calculate for
        [Parameter(ValueFromPipelineByPropertyName=$true, 
                    ValueFromRemainingArguments=$false, 
                    Position=0)]
        [int[]]
        $Ages = 29, #18..60,
    
        # Enter a specific gender as a [Char[]]
        [Char[]]
        $Genders = @("M", "F"),

        # Provide a valid [timespan] value to measure at a specific scale (e.g."hh:mm:ss.0"
        [timespan]
        $Scale = "00:00:01"
    )
    
    Begin
    {
        $ProfileURI = "https://www.dfit.ca/forceprofile/get_metric_scores"
        $Test= @{
            Eval=[ordered]@{
                rush=@{'low'=[timespan]"00:00:27";'high'=[timespan]"00:00:52"}
                sbl=@{'low'=[timespan]"00:00:40";'high'=[timespan]"00:03:31"}
                ls=@{'low'=[timespan]"00:02:00";'high'=[timespan]"00:05:31"}
                sbd=@{'low'=[timespan]"00:00:9";'high'=[timespan]"00:00:52"}
            }
        }

        $Results = @()

    }
    Process
    {
        if ($pscmdlet.ShouldProcess("Ages: $Ages and Genders: $Genders", "Gather Fitness Data"))
        {
            Foreach($Age in $Ages){
            Foreach($Gender in $Genders) {
            ForEach ($Key in $Test.Eval.Keys) {
                Write-Verbose "Testing for $Age Year old $(if($Gender -eq "M"){"Males"}else{"Females"}) performing $key"
                $time = $Test.Eval[$key].low
                do {
                    $Min = $time.Minutes
                    $Sec = $time.Seconds
                    $Dec = $time.Milliseconds
                    $SerializedData = "age=$Age&gender=$Gender&$Key`_mins=$Min&$Key`_secs=$Sec&$Key`_dec=$Dec"
                    $KeyScore = Invoke-RestMethod -Method Post -Uri $ProfileURI -Body $SerializedData -Verbose:$false

                    $Results += @{Age=$Age;Gender=$Gender;Key=$Key;Mins=$Min;Sec=$Sec;
                            #total_op_score=$KeyScore.total_op_score;
                            overall_adjusted_score=$KeyScore.overall_adjusted_score}

                    $time += $Scale
                }
                while ($time -lt $Test.Eval[$key].high);
            }
            }
            }
        }
    }
    End
    {
        Write-Verbose "Finalizing results"
        Write-Output $Results | % { [PSCustomObject] $_ }  | select Age, Gender, Mins, Sec, Key, overall_adjusted_score
    }
}