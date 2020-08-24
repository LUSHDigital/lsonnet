{
  // containsEnvVars checks that all needles (k8s env variable "name" and "value" objs) exist in the haystack (pod env block) object
  containsEnvVars(haystack, needles):: (
    // create an array, 1 element per needle
    local results = [
      // check the needle is valid (it contains the two required fields)
      if (std.objectHas(needle, 'name') && std.objectHas(needle, 'value')) then
        // needle is valid

        // create a sub array to contain result of every haystack item for the current needle
        local h = [
          // if the haystack name and value both match the needle, add 'true' to the sub array
          if (needle.name == haystackItem.name) && needle.value == haystackItem.value then true
          for haystackItem in haystack
        ];
        // strip out the nulls, leaving only a true for the items where the needle and haystack match
        local prunedResults = std.prune(h);

        if std.length(prunedResults) == 0 then
          false
        else
          true
      else
        // needle is not value, raise an error
        error 'needle ' + needle + ': doesnt contain the fields "name" and "value"'
      // body of the loop is the above logic
      for needle in needles
    ];

    // remove the empty sub arrays, these are where a needle was not matched to a haystackItem
    // therefore indicate a needle wasn't found
    local prunedResults = std.prune(results);

    //the number of results (bool true) remaining should equal the number of needles, indicating they were all found
    if std.count(prunedResults, true) < std.length(needles) then
      false
    else
      true
  ),

  // containsSecretEnvVars checks that all needles exist in the haystack (pod env block) object
  // Example needle: [{ name: 'JWT_PRIVATE_KEY', valueFrom: { secretKeyRef: { key: 'app.rsa.pub', name: 'jwtsigning' } } }]
  containsSecretEnvVars(haystack, needles):: (
    // create an array, 1 element per needle
    local results = [
      // create a sub array to contain result of every haystack item for the current needle
      local h = [
        // if the haystack values match the needle, add 'true' to the sub array
        if (needle.name == haystackItem.name) &&
           (needle.valueFrom.secretKeyRef.key == haystackItem.valueFrom.secretKeyRef.key) &&
           (needle.valueFrom.secretKeyRef.name == haystackItem.valueFrom.secretKeyRef.name)
        then
          true
        for haystackItem in haystack
      ];
      // strip out the nulls, leaving only a true for the items where the needle and haystack match
      local prunedResults = std.prune(h);

      if std.length(prunedResults) == 0 then
        false
      else
        true
      for needle in needles
    ];

    // remove the empty sub arrays, these are where a needle was not matched to a haystackItem
    // therefore indicate a needle wasn't found
    local prunedResults = std.prune(results);

    //the number of results (bool true) remaining should equal the number of needles, indicating they were all found
    if std.count(prunedResults, true) < std.length(needles) then
      false
    else
      true
  ),

  // containsObject will assert that the k:v's provided exist in the haystack object
  containsObjects(haystack, needles):: (

    // creaate a local array containing the element 'true' if the key and value of each needle exists in haystack
    local results = [
      if std.objectHas(haystack, need) && (needles[need] == haystack[need]) then
        true
      else
        false
      for need in std.objectFields(needles)
    ];

    // results will contain 'true' or 'null' if a needle was matched. strip out the 'nulls'
    local prunedResults = std.prune(results);

    // if the number of 'true's left is the same length as the needles, then assume everything was found and return true
    if std.count(prunedResults, true) < std.length(needles) then
      false
    else
      true
  ),

  // prettyPrint pretty prints json objects for use in reporting tests
  // format of objects will be [{ title: json}, {title2: json2}]
  prettyDebug(objects):: (
    local strings = [
      '\n' + object.title + ' is ' + std.manifestJsonEx(object.json, '  ')
      for object in objects
    ];

    std.trace(std.join('\n', strings), 'true')
  ),
}
