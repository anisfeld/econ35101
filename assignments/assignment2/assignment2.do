* Assignment 2 -- Gravity many ways
clear
clear matrix
clear mata

ssc install ftools
ssc install hdfe
ssc install reghdfe
ssc install ppml
ssc install poi2hdfe
ssc install ppmlhdfe
ssc install estout


global table_1 = "off"

set maxvar 32000
set matsize  11000
* Jordan change this!
cd ~/econ35101/assignments/assignment2/

import delimited data/Detroit.csv, clear

* munge data
gen log_d = log(distance_google_miles)
gen log_time = log(duration_minutes)
gen log_flow = log(flow) if flow > 0

gen log_flow_plus_1 = log(flow + 1)
gen log_flow_plus_eps = log(flow + .01)


egen xjj = max((home_id == work_id) * flow), by(home_id)
gen log_flow_xjj = log(flow) 
replace log_flow_xjj = log(xjj / 10^12) if flow == 0

***********************
**  Table 1
***********************
if ("${table_1}" == "on") {
preserve
drop if flow == 0

foreach dep in log_d log_time {

eststo clear
timer clear
timer on 1
qui reg log_flow `dep' i.home_id i.work_id //, vce(robust)
timer off 1
qui timer list
eststo , add(time r(t1))
* for part 2
hettest

timer on 2
xtset home_id work_id
qui xtreg log_flow `dep' i.work_id, fe // vce(robust)
timer off 2
qui timer list
eststo , add(time r(t2))

timer on 3
* Though a FWL argument suggest this should work, the point estimate is 
* off by roughly .005, perhaps due to rounding errors.
* areg log_d, absorb(home_id)
* predict log_d_tilde, residuals
* areg log_flow, absorb(home_id)
* predict log_flow_tilde, residuals
* areg log_flow_tilde log_d_tilde, absorb(work_id) vce(robust) 
qui areg log_flow `dep' i.home_id, absorb(work_id) // vce(robust)
timer off 3
qui timer list
eststo , add(time r(t3))


timer clear
timer on 4
qui reghdfe log_flow `dep', absorb(home_id work_id) // vce(robust)
timer off 4
qui timer list
eststo , add(time r(t4))


esttab using ./out/table_1_`dep'.tex, se r2 /// 
    keep(`dep') nostar ///
    mtitles("reg" "xtreg" "areg" "reghdfe") ///
    title("Table 1:`dep' on log Flow, with Flow > 0") ///
    scalars(time) sfmt(%8.2f) replace
}

restore
}
***********************
**  Table 2
***********************

eststo clear
preserve
drop if flow == 0

local ys log_flow log_flow_plus_1 ///
           log_flow_plus_1 log_flow_plus_eps ///
	   log_flow_xjj
	  
local i 1
	  
foreach y of local ys {
    timer clear
    timer on 1
    qui reghdfe `y' log_d, absorb(home_id work_id)
    timer off 1
    qui timer list
    eststo , add(time r(t1))
    
    if (`i' == 1) {
	qui reghdfe `y' log_d, absorb(home_id work_id) residuals(res_hdfe)
	predict yhat, xb
	scatter res_hdfe yhat
	graph export ./out/resid_plot.png, replace
    }
    
    if (`i' == 2) { 
	restore 
    }		
    
    local i `i' + 1
}


timer on 2
qui poi2hdfe flow log_d, id1(home_id) id2(work_id)
timer off 2
qui timer list
eststo , add(time r(t2))


timer on 3
qui ppmlhdfe flow log_d, absorb(home_id work_id)
timer off 3
qui timer list
eststo , add(time r(t3))

timer on 4
qui ppmlhdfe flow log_d if flow > 0, absorb(home_id work_id) 
timer off 4
qui timer list
eststo , add(time r(t4))

timer clear
timer on 4
qui reghdfe log_flow `dep', absorb(home_id work_id) // vce(robust)
timer off 4
qui timer list
eststo , add(time r(t4))

******
preserve

timer clear
timer on 4
qui reghdfe log_flow log_d, absorb(home_id work_id) vce(robust)
timer off 4
qui timer list
eststo , add(time r(t4))


