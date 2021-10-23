clear
clear mata
set matsize 10000
set maxvar 32000
ssc install ftools
ssc install reghdfe
ssc install ppml
ssc install poi2hdfe
ssc install ppmlhdfe

cd ~/econ35101/assignments/assignment2/

import delimited data/Detroit.csv

gen log_distance = log(distance_google_miles)
gen log_time = log(duration_minutes)
gen log_flow = log(flow) if flow > 0
reg log_flow log_distance i.home_id i.work_id if flow > 0, vce(robust)
* matches -.40716 

xtset home_id work_id
xtreg log_flow log_distance if flow > 0, fe vce(robust)

areg log_flow if flow > 0, absorb(home_id)
predict resid_flow, residuals
areg log_distance if flow > 0, absorb(home_id)
predict resid_distance, residuals
areg resid_flow resid_distance if flow > 0, absorb(work_id) vce(robust)

reghdfe log_flow log_distance if flow > 0, absorb(home_id work_id) vce(robust)

************************
* zeros
************************

gen log_flow_plus_1 = log(flow + 1)
gen log_flow_plus_eps = log(flow + 0.01)
egen x_jj = max((home_id == work_id) * flow)), by(work_id)
gen log_flow_x_jj = flow
replace log_flow_x_jj = x_jj*10e-12 if flow == 0

*1
reghdfe log_flow log_distance if flow > 0, absorb(home_id work_id) vce(robust)
*2
reghdfe log_flow_plus_1 log_distance if flow > 0, absorb(home_id work_id) vce(robust)
*3
reghdfe log_flow_plus_1 log_distance, absorb(home_id work_id) vce(robust)
*4
reghdfe log_flow_plus_eps log_distance, absorb(home_id work_id) vce(robust)
*5 take ij to imply i-> j
reghdfe log_flow_x_jj log_distance, absorb(home_id work_id) vce(robust)
