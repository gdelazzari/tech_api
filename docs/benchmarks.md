+ As of commit 12ab2f04a54c54e1d69efa5409096ad95c06c695 with recursive network
  traversal
  + Full traversal on a network of 2000 transporter nodes and 500 devices:
    *17.67ms (10 runs average)*
  + Full traversal on a network of 5000 transporter nodes and 2500 devices:
    *52.63ms (10 runs average)*
  + Full traversal on a network of more than 5000 transporter nodes:
    *stack overflow*


+ With recursive network traversal (next commit)
  + Full traversal on a network of 2000 transporter nodes and 500 devices:
    *17.71ms (10 runs average)*
  + Full traversal on a network of 5000 transporter nodes and 2500 devices:
    *55.75ms (10 runs average)*
  + Full traversal on a network of 10000 transporter nodes and 2500 devices:
    *105.46ms (10 runs average)*
  + Full traversal on a network of 20000 transporter nodes and 10000 devices:
    *252.12ms (10 runs average)*
