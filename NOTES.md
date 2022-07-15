# NOTES

## Strategy to fix the handover crapshow

The existence of MpcOffender#handover_case directly maps to whether that offender is currently has an open handover

## WTF

Why does HandoverDateService build in-memory CalculatedHandoverDate objects instead of querying the database? IT
DOES THIS EVERY TIME EVEN WHEN IT IS SAVING A NEW CALCULATEDHANDOVERDATE - JUST ACCEPT IT.

## How do I get a list of upcoming handovers?

The list is for the currently logged in POM. The OLD page shows ALL handovers on tab-1, and current-user-who-is-a-pom's
cases on tab-2. And we finally have some success! That's what I need to replicate.

MpcOffender#approaching_handover? is the kind of logic I need to replicate.
CaseloadHandoversController#index has the kind of logic I need. It GETS ALL ALLOCATIONS
AND ITERATES THROUGH THEM IN MEMORY! It has to I guess, as it has to make the API call
to get the MpcOffender for each one, then check handover_date.

HandoverDateService - if case is a policy case - calculates handover date in ::handover
(in the policy case conditional's body) and ::nps_start_date

## Random Notes

PrisonsApplicationController has before_action of load_staff_member for every action, which sets
@current_user(StaffMember) and @staff_id(NOMIS staff_id)

PrisonsApplicationController#load_pom is called before legacy handovers page

I still don't understand what changes RecalculatehandoverDateJob is making to the DB -
the data it builds never seems to be used as the HandoverDateService just rebuilds the
model in-memory wherever it is used. It's only use seems to only send out emails.
