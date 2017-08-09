## Measuring Performance Portability

As discussed in the previous section, performance portability can be an elusive topic to quantify 
and different engineers often provide different definitions or measurement techniques.

Measuring 'portability' itself is somewhat more well defined. One can, in principle, measure the 
total lines of code used in common across different architectures vs. the amount of code intended 
for a single architecture via ``IFDEF`` pre-processing statements and the like. A code with 0% 
architecture specfic code being completely portable and a code with a 100% architecture specific 
code being essentially made up of multiple applications. 

'Performance', even on a single architecture, is a bit less simple to define and measure. In 
practice, scientists generally care about the quality and quantity of scientific output they 
produce. This typically maps for them to relative performance concepts, such as how much faster 
can a particular run or set of runs run today than yesterday or on this machine than that. The 
drawback of trying to measure performance in this way is that the baseline is arbitrary - i.e. you 
don't know how well your code is performing on any architecture compared to how it 'should' be 
performing if it were well optimized.

One may 
in principle define absolute performance as a measure of

