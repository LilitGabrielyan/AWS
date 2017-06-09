/**
 * Created by lilit on 6/7/17.
 */
var AWS = require('aws-sdk');

var cloudfront = new AWS.CloudFront({apiVersion: '2017-03-25'});

exports.test = (event, context, callback) => {

	var params = {
		DistributionId: process.env.distributionId,
		InvalidationBatch: {
			CallerReference: new Date().getTime(),
			Paths: {
				Quantity: 0,
				Items: [
					'*',

				]
			}
		}
	};
	cloudfront.createInvalidation(params, function(err, data) {
		if (err) {
			console.log(err, err.stack);
		}
		else     {
			console.log(data);
		}
	});

}