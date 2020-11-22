const fragment = r'''
  fragment orderFields on Order {
    __typename
    id
    createdUtc
    updatedUtc
    orderState
    name
    orderNumber
    place {
      __typename
      id
      name
    }
    orderLines {
      __typename
      id
      price
      quantity
      unitPrice
      orderLineState
      createdUtc
      product {
        __typename
        id
        name
        priceSell
        printingDeviceId
      }
    }
  }
''';

const mutation = r'''
  mutation CreateOrder($placeId: ID!, $lines: [OrderLineCreate!]!, $name: String) {
    createOrder(data: {
      placeId: $placeId
      lines: $lines
      name: $name
    }){
      ...orderFields
    }
  }
''' +
    fragment;

/// Reproduction should be that we see the expected place (and maybe product), but the old order
const expectedResult = {
  '__typename': 'Order',
  'id': 'order-aaaa-aaaa-aaaa-aaaaaaaaaaaa',
  'createdUtc': 1605999494381,
  'updatedUtc': 1605999494381,
  'orderState': 'Opened',
  'name': null,
  'orderNumber': 'MY2020000019',
  'place': {
    '__typename': 'Place',
    'id': 'place-aaaa-aaaa-aaaa-aaaaaaaaaaaa',
    'name': 'Bar 3',
  },
  'orderLines': [
    {
      '__typename': 'OrderLine',
      'id': 'orderline-aaaa-aaaa-aaaa-aaaaaaaaaaaa',
      'price': 5000,
      'quantity': 1,
      'unitPrice': 5000,
      'orderLineState': 'Opened',
      'createdUtc': 1605999494381,
      'product': {
        '__typename': 'Product',
        'id': 'product-aaaa-aaaa-aaaa-aaaaaaaaaaaa',
        'name': 'Red label glass',
        'priceSell': 5000,
        'printingDeviceId': 'printer-aaaa-aaaa-aaaa-aaaaaaaaaaaa'
      },
    },
  ],
};

const openOrderLineCreate = {
  'price': 5000,
  'quantity': 1,
  'unitPrice': 5000,
  'product': {
    'id': 'product-aaaa-aaaa-aaaa-aaaaaaaaaaaa',
    'name': 'Red label glass',
    'priceSell': 5000,
  },
};

const closedOrder = {
  '__typename': 'Order',
  'id': 'order-bbbb-bbbb-bbbb-bbbbbbbbbbbb',
  'createdUtc': 1605998577724,
  'updatedUtc': 1605998625731,
  'orderState': 'Closed',
  'name': null,
  'orderNumber': 'MY2020000005',
  'place': {
    '__typename': 'Place',
    'id': 'place-aaaa-aaaa-aaaa-aaaaaaaaaaaa',
    'name': 'Bar 3',
  },
  'orderLines': [
    {
      '__typename': 'OrderLine',
      'id': 'orderline-bbbb-bbbb-bbbb-bbbbbbbbbbbb',
      'price': 5000,
      'quantity': 1,
      'unitPrice': 5000,
      'orderLineState': 'Paid',
      'createdUtc': 1605998577724,
      'product': {
        '__typename': 'Product',
        'id': 'product-bbbb-bbbb-bbbb-bbbbbbbbbbbb',
        'name': 'blue label glass',
        'priceSell': 5000,
        'printingDeviceId': 'printer-bbbb-bbbb-bbbb-bbbbbbbbbbbb',
      }
    }
  ]
};

const closedOrderLineCreate = {
  'price': 5000,
  'quantity': 1,
  'unitPrice': 5000,
  'product': {
    'id': 'product-bbbb-bbbb-bbbb-bbbbbbbbbbbb',
    'name': 'blue label glass',
    'priceSell': 5000,
  }
};
