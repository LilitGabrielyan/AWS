/**
 * Created by lilit on 6/7/17.
 */
var AWS = require('aws-sdk');

var cloudfront = new AWS.CloudFront({apiVersion: process.env.apiVersion});
var lambda = new AWS.Lambda({region: process.env.region, apiVersion: '2015-03-31'});

exports.test = (event, context, callback) => {

	var params = {
		DistributionId: process.env.distributionId,
		InvalidationBatch: {
			CallerReference: "date_" + new Date().getTime(),
			Paths: {
				Quantity: 0,
				Items: [
					'*',

				]
			}
		}
	};

	// create JSON object for parameters for invoking Lambda function
	var pullParams = {
		FunctionName : 'invalidationStarted',
		InvocationType : 'RequestResponse',
		LogType : 'None'
	};
	lambda.invoke(pullParams, function(error, data) {
		if (error) {
			console.log("Error while triggering start process lambda")
		} else {
			console.log("Success while triggering start process lambda")
		}
	});

	cloudfront.createInvalidation(params, function(err, data) {
		if (err) {
			console.log(err, err.stack);
		}
		else     {
			console.log(data);

			// create JSON object for parameters for invoking Lambda function
			var pullParams = {
				FunctionName : 'invalidationFinished',
				InvocationType : 'RequestResponse',
				LogType : 'None'
			};
			lambda.invoke(pullParams, function(error, data) {
				if (error) {
					console.log("Error while triggering finish process lambda")
				} else {
					console.log("Success while triggering finish process lambda")
				}
			});
		}
	});

}