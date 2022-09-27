require 'invoice_printer'

def euro(number)
  format '%.2f €', number
end

def format_item(item_raw)
  InvoicePrinter::Document::Item.new(
    name: item_raw.name,
    unit: item_raw.unit,
    quantity: item_raw.quantity.to_s,
    price: euro(item_raw.price),
    amount: euro(item_raw.amount)
    # tax: euro(item_raw.tax)
  )
end

item_raw_struct = Struct.new(:name, :unit, :quantity, :price) do
  def amount
    price * quantity
  end

  def tax
    amount * 0.2
  end
end

items_raw = [
  ['Jour de travail', 'jour', 10, 650]
].map { item_raw_struct.new(*_1) }

InvoicePrinter.labels = {
  name: 'Facture',
  provider: 'Émetteur',
  purchaser: 'Destinataire',
  tax_id: 'Numéro de TVA',
  payment: 'Règlement',
  payment_by_transfer: "Règlement par virement bancaire à l'IBAN suivant:",
  account_number: '',
  swift: 'SWIFT',
  iban: 'IBAN',
  issue_date: "Date d'émission",
  due_date: 'Date limite de règlement',
  # variable_symbol: 'Variable symbol',
  item: 'Item',
  variable: '',
  quantity: 'Quantité',
  unit: 'Unité',
  price_per_item: 'Prix unitaire HT',
  amount: 'Total HT',
  tax: 'TVA 20%',
  # tax2: 'Tax 2',
  # tax3: 'Tax 3',
  subtotal: 'Total HT',
  total: 'Total TTC'
}

InvoicePrinter.print(
  document: InvoicePrinter::Document.new(
    number: 'Facture numéro 202209-38',
    provider_name: 'OUT OF SCREEN',
    provider_lines: [
      '122 rue Amelot, 75011, Paris',
      'adrien@outofscreen.com',
      '84526029800011',
      'Numéro de TVA FR19845260298'
    ].join("\n"),
    purchaser_name: 'SCOP /ut7',
    purchaser_lines: [
      '14 avenue Ledru-Rollin, 75012, Paris',
      '502529795',
      'Numéro de TVA FR71502529795'
    ].join("\n"),
    issue_date: '27/09/2022',
    due_date: '27/12/2022',
    subtotal: euro(items_raw.map(&:amount).sum),
    tax: euro(items_raw.map(&:tax).sum),
    total: euro(items_raw.map(&:amount).sum * 1.2),
    bank_account_number: [
      'FR76 1695 8000 0113 5599 9575 445',
      '',
      'BIC QNTOFRP1XXX'
    ].join("\n"),
    items: items_raw.map { format_item(_1) }
  ),
  file_name: 'facture.pdf'
)
