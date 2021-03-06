# Definition

## Definition

The 2016 DOE Center of Excellence (COE) meeting in Phoenix brought together engineers from the DOE's Office of Science and National Nuclear Security Agency 
as well as vendor staff (from Intel, NVIDIA, IBM, Cray and others) to share portability lessons and best practices from their respective app-readiness 
programs. One of the high-level take-away messages from the meeting is that "there is not yet a universally accepted definition of 'performance 
portability'". 
There is generally agreement on what performance-portability "basically means" but the exact details differ in everyone's idea for the term. A number of 
attendees 
gave the following definitions:

* "For the purposes of this meeting, it is the ability to run an application with acceptable performance across KNL and GPU-based systems with a single 
version of source code." (Rob Neely)

* "An application is performance portable if it achieves a consistent level of performance (e.g. defined by execution time or
other figure of merit (not percentage of peak flops across platforms)) relative to the best known implementation on each platform." (John Pennycook, Intel)

* "Hard portability = no code changes and no tuning. Software portability = simple code mods with no algorithmic changes. Non-portable = algorithmic changes" (Adrian Pope, Vitali Morozov)

* (Performance portability means) the same source code will run productively on a variety of different architectures" (Larkin)

* "Code is performance portable when the application team says its performance portable!" (Richards)

For our purposes, we combine a few of the ideas above into the following working definition:

<br>
**An application is performance portable if it achieves a consistent ratio of the actual time to solution to either the best-known or the theoretical best time to 
solution on each platform with minimal platform specific code required.**
<br><br>

We discuss the details on how to begin to quantify the level to which a code meets this definition on the 
[Measurement Techniques](/perfport/measurements/index.md) page. While the above definition and the following metrics don't fulfill every vision of performance-portability - we consider them a useful way to frame the conversation and lead to efforts to understand application-performance on mutliple architectures which is nearly always productive.

