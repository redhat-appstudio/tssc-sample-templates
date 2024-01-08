# http 

## HTTP Application 
This template provides a standard HTTP component consisting of a deployment, service and route. 

The following day 2 edit/update operations supported:
    set/get image - updates the image for this component 
    set/get replicas

## Example
```
    tad add-component c1 http 
    tad set c1 replicas 3     
```  